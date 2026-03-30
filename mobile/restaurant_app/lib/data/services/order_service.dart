import '../../core/constants/constants.dart';
import '../models/order_model.dart';
import 'api_service.dart';

/// Service for order-related API calls
class OrderService {
  final ApiService _apiService = ApiService();

  /// Create new order
  Future<Order?> createOrder(Map<String, dynamic> orderData) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.orders,
      body: orderData,
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      return Order.fromJson(response.data!);
    }
    return null;
  }

  /// Get user's orders with pagination
  Future<List<Order>> getOrders({int page = 1, int pageSize = 10}) async {
    final response = await _apiService.get<List>(
      ApiConstants.orders,
      queryParams: {'page': page, 'pageSize': pageSize},
      fromJson: (data) => data as List,
    );

    if (response.success && response.data != null) {
      return response.data!
          .map((item) => Order.fromJson(item))
          .toList();
    }
    return [];
  }

  /// Get order by ID
  Future<Order?> getOrderById(int id) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '${ApiConstants.orders}/$id',
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      return Order.fromJson(response.data!);
    }
    return null;
  }

  /// Track order status
  Future<Map<String, dynamic>?> trackOrder(int id) async {
    final trackUrl = ApiConstants.orderTrack.replaceAll('{id}', id.toString());
    final response = await _apiService.get<Map<String, dynamic>>(
      trackUrl,
      fromJson: (data) => data as Map<String, dynamic>,
    );

    if (response.success && response.data != null) {
      return response.data!;
    }
    return null;
  }

  /// Cancel order
  Future<bool> cancelOrder(int id, String reason) async {
    final cancelUrl = ApiConstants.orderCancel.replaceAll('{id}', id.toString());
    final response = await _apiService.post(
      cancelUrl,
      body: {'reason': reason},
    );

    return response.success;
  }

  /// Reorder (create new order from existing order)
  Future<Order?> reorder(int orderId) async {
    // First get the order details
    final order = await getOrderById(orderId);
    if (order == null) return null;

    // Create new order with same items
    final orderData = {
      'branchId': order.branchId,
      'items': order.items.map((item) => {
        'menuItemId': item.menuItemId,
        'quantity': item.quantity,
        'specialInstructions': item.specialInstructions,
      }).toList(),
      'deliveryAddressId': order.deliveryAddressId,
      'paymentMethod': order.paymentMethod,
    };

    return await createOrder(orderData);
  }

  // Deprecated: Auth token is now handled globally by ApiService interceptor
  void setAuthToken(String token) {}
}
