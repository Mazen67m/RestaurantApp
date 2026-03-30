import 'dart:async';
import 'package:flutter/material.dart';
import '../services/signalr_service.dart';
import '../services/api_service.dart';
import '../../core/constants/constants.dart';
import 'auth_provider.dart';

/// Provider for managing real-time order updates via SignalR
class OrderTrackingProvider extends ChangeNotifier {
  OrderSignalRService? _signalRService;
  final AuthProvider _authProvider;
  
  SignalRConnectionState _connectionState = SignalRConnectionState.disconnected;
  OrderStatusUpdate? _latestStatusUpdate;
  OrderReadyNotification? _latestReadyNotification;
  
  final List<StreamSubscription> _subscriptions = [];
  int? _currentTrackingOrderId;

  SignalRConnectionState get connectionState => _connectionState;
  OrderStatusUpdate? get latestStatusUpdate => _latestStatusUpdate;
  OrderReadyNotification? get latestReadyNotification => _latestReadyNotification;
  bool get isConnected => _connectionState == SignalRConnectionState.connected;

  OrderTrackingProvider({
    required AuthProvider authProvider,
  }) : _authProvider = authProvider;

  void _setupListeners() {
    if (_signalRService == null) return;

    // Clear existing subscriptions
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();

    // Listen to connection state changes
    _subscriptions.add(
      _signalRService!.connectionState.listen((state) {
        _connectionState = state;
        notifyListeners();
        
        // Rejoin groups on reconnect
        if (state == SignalRConnectionState.connected) {
          _rejoinGroups();
        }
      }),
    );

    // Listen to order status updates
    _subscriptions.add(
      _signalRService!.orderStatusUpdates.listen((update) {
        if (_currentTrackingOrderId == update.orderId) {
          _latestStatusUpdate = update;
          notifyListeners();
        }
      }),
    );

    // Listen to order ready notifications
    _subscriptions.add(
      _signalRService!.orderReadyNotifications.listen((notification) {
        _latestReadyNotification = notification;
        notifyListeners();
      }),
    );
  }

  /// Connect to SignalR hub
  Future<bool> connect() async {
    final token = await _authProvider.getToken();
    if (token == null) {
      return false;
    }

    if (_signalRService != null) {
      _signalRService!.disconnect();
    }

    _signalRService = OrderSignalRService(
      baseUrl: ApiConstants.baseUrl.replaceAll('/api', ''), // Hub usually at base
      authToken: token,
    );

    _setupListeners();
    return await _signalRService!.connect();
  }

  /// Disconnect from SignalR hub
  void disconnect() {
    _signalRService?.disconnect();
  }

  /// Start tracking a specific order
  Future<void> startTrackingOrder(int orderId) async {
    if (!isConnected) {
      final connected = await connect();
      if (!connected) return;
    }
    
    // Leave previous order group if any
    if (_currentTrackingOrderId != null && _currentTrackingOrderId != orderId) {
      await _signalRService?.leaveOrderGroup(_currentTrackingOrderId!);
    }
    
    _currentTrackingOrderId = orderId;
    _latestStatusUpdate = null;
    await _signalRService?.joinOrderGroup(orderId);
    notifyListeners();
  }

  /// Stop tracking current order
  Future<void> stopTrackingOrder() async {
    if (_currentTrackingOrderId != null) {
      await _signalRService?.leaveOrderGroup(_currentTrackingOrderId!);
      _currentTrackingOrderId = null;
      _latestStatusUpdate = null;
      notifyListeners();
    }
  }

  /// Subscribe to customer's order updates
  Future<void> subscribeToCustomerUpdates() async {
    if (!isConnected) {
      final connected = await connect();
      if (!connected) return;
    }
    
    final userId = _authProvider.user?.id;
    if (userId != null) {
      await _signalRService?.joinCustomerGroup(userId.toString());
    }
  }

  void _rejoinGroups() async {
    if (_signalRService == null) return;

    if (_currentTrackingOrderId != null) {
      await _signalRService!.joinOrderGroup(_currentTrackingOrderId!);
    }
    
    final userId = _authProvider.user?.id;
    if (userId != null) {
      await _signalRService!.joinCustomerGroup(userId.toString());
    }
  }

  /// Clear the latest notifications after they've been shown
  void clearNotifications() {
    _latestReadyNotification = null;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _signalRService?.dispose();
    super.dispose();
  }
}
