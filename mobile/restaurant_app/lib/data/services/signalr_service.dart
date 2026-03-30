import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// SignalR connection states
enum SignalRConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// Order status update from SignalR
class OrderStatusUpdate {
  final int orderId;
  final String status;
  final String statusText;
  final String? estimatedTime;
  final DateTime updatedAt;

  OrderStatusUpdate({
    required this.orderId,
    required this.status,
    required this.statusText,
    this.estimatedTime,
    required this.updatedAt,
  });

  factory OrderStatusUpdate.fromJson(Map<String, dynamic> json) {
    return OrderStatusUpdate(
      orderId: json['orderId'],
      status: json['status']?.toString() ?? '',
      statusText: json['statusText'] ?? '',
      estimatedTime: json['estimatedTime'],
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}

/// New order notification
class NewOrderNotification {
  final int orderId;
  final String orderNumber;
  final String customerName;
  final int itemCount;
  final double total;
  final String orderType;
  final DateTime createdAt;

  NewOrderNotification({
    required this.orderId,
    required this.orderNumber,
    required this.customerName,
    required this.itemCount,
    required this.total,
    required this.orderType,
    required this.createdAt,
  });

  factory NewOrderNotification.fromJson(Map<String, dynamic> json) {
    return NewOrderNotification(
      orderId: json['orderId'],
      orderNumber: json['orderNumber'] ?? '',
      customerName: json['customerName'] ?? '',
      itemCount: json['itemCount'] ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      orderType: json['orderType'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Order ready notification
class OrderReadyNotification {
  final int orderId;
  final String message;
  final bool isDelivery;

  OrderReadyNotification({
    required this.orderId,
    required this.message,
    required this.isDelivery,
  });

  factory OrderReadyNotification.fromJson(Map<String, dynamic> json) {
    return OrderReadyNotification(
      orderId: json['orderId'],
      message: json['message'] ?? '',
      isDelivery: json['isDelivery'] ?? false,
    );
  }
}

/// SignalR service for real-time order updates
/// Note: This is a simplified implementation using long-polling
/// For production, consider using signalr_netcore or signalr_flutter package
class OrderSignalRService {
  final String baseUrl;
  final String? authToken;
  
  SignalRConnectionState _connectionState = SignalRConnectionState.disconnected;
  String? _connectionId;
  Timer? _pollTimer;
  bool _isPolling = false;
  
  // Stream controllers for different events
  final _connectionStateController = StreamController<SignalRConnectionState>.broadcast();
  final _orderStatusUpdateController = StreamController<OrderStatusUpdate>.broadcast();
  final _newOrderController = StreamController<NewOrderNotification>.broadcast();
  final _orderReadyController = StreamController<OrderReadyNotification>.broadcast();
  
  // Public streams
  Stream<SignalRConnectionState> get connectionState => _connectionStateController.stream;
  Stream<OrderStatusUpdate> get orderStatusUpdates => _orderStatusUpdateController.stream;
  Stream<NewOrderNotification> get newOrders => _newOrderController.stream;
  Stream<OrderReadyNotification> get orderReadyNotifications => _orderReadyController.stream;
  
  SignalRConnectionState get currentState => _connectionState;

  OrderSignalRService({
    required this.baseUrl,
    this.authToken,
  });

  /// Connect to the SignalR hub
  Future<bool> connect() async {
    if (_connectionState == SignalRConnectionState.connected) {
      return true;
    }

    _updateState(SignalRConnectionState.connecting);

    try {
      // Negotiate connection
      final negotiateUrl = '$baseUrl/hubs/orders/negotiate';
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.post(
        Uri.parse(negotiateUrl),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _connectionId = data['connectionId'];
        _updateState(SignalRConnectionState.connected);
        _startPolling();
        return true;
      } else {
        _updateState(SignalRConnectionState.disconnected);
        return false;
      }
    } catch (e) {
      _updateState(SignalRConnectionState.disconnected);
      return false;
    }
  }

  /// Disconnect from the SignalR hub
  void disconnect() {
    _stopPolling();
    _connectionId = null;
    _updateState(SignalRConnectionState.disconnected);
  }

  /// Join order group to receive updates for a specific order
  Future<void> joinOrderGroup(int orderId) async {
    await _invokeHubMethod('JoinOrderGroup', [orderId.toString()]);
  }

  /// Leave order group
  Future<void> leaveOrderGroup(int orderId) async {
    await _invokeHubMethod('LeaveOrderGroup', [orderId.toString()]);
  }

  /// Join customer group to receive all customer order updates
  Future<void> joinCustomerGroup(String customerId) async {
    await _invokeHubMethod('JoinCustomerGroup', [customerId]);
  }

  /// Leave customer group
  Future<void> leaveCustomerGroup(String customerId) async {
    await _invokeHubMethod('LeaveCustomerGroup', [customerId]);
  }

  /// Invoke a hub method
  Future<void> _invokeHubMethod(String method, List<String> args) async {
    if (_connectionId == null) {
      return;
    }

    try {
      final url = '$baseUrl/hubs/orders?id=$_connectionId';
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final body = jsonEncode({
        'type': 1, // Invocation
        'target': method,
        'arguments': args,
      });

      await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
    } catch (e) {}
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _poll();
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isPolling = false;
  }

  Future<void> _poll() async {
    if (_isPolling || _connectionId == null) return;
    _isPolling = true;

    try {
      final url = '$baseUrl/hubs/orders?id=$_connectionId';
      final headers = <String, String>{};
      
      if (authToken != null) {
        headers['Authorization'] = 'Bearer $authToken';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        _handleMessages(response.body);
      }
    } catch (e) {
      if (_connectionState == SignalRConnectionState.connected) {
        _updateState(SignalRConnectionState.reconnecting);
        // Try to reconnect
        Future.delayed(const Duration(seconds: 3), () => connect());
      }
    } finally {
      _isPolling = false;
    }
  }

  void _handleMessages(String data) {
    try {
      // SignalR messages are separated by record separator (0x1E)
      final messages = data.split('\x1E').where((m) => m.isNotEmpty);
      
      for (final message in messages) {
        final json = jsonDecode(message);
        final type = json['type'];
        final target = json['target'];
        final arguments = json['arguments'] as List?;

        if (type == 1 && target != null && arguments != null && arguments.isNotEmpty) {
          _handleHubMessage(target, arguments[0]);
        }
      }
    } catch (e) {}
  }

  void _handleHubMessage(String target, dynamic data) {
    switch (target) {
      case 'OrderStatusUpdated':
        final update = OrderStatusUpdate.fromJson(data);
        _orderStatusUpdateController.add(update);
        break;
        
      case 'NewOrder':
        final notification = NewOrderNotification.fromJson(data);
        _newOrderController.add(notification);
        break;
        
      case 'OrderReady':
        final notification = OrderReadyNotification.fromJson(data);
        _orderReadyController.add(notification);
        break;
        
      default:
        break;
    }
  }

  void _updateState(SignalRConnectionState state) {
    _connectionState = state;
    _connectionStateController.add(state);
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _orderStatusUpdateController.close();
    _newOrderController.close();
    _orderReadyController.close();
  }
}
