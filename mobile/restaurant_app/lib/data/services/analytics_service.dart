import 'package:flutter/foundation.dart';

/// Service for Analytics and Crash reporting
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  /// Log a custom event
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    if (kDebugMode) {
      print('Analytics Event: $name, Params: $parameters');
    }
    // In production:
    // await FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
  }

  /// Log user login
  Future<void> logLogin(String method) async {
    await logEvent('login', parameters: {'method': method});
  }

  /// Log item view
  Future<void> logViewItem(int id, String name) async {
    await logEvent('view_item', parameters: {
      'item_id': id,
      'item_name': name,
    });
  }

  /// Log add to cart
  Future<void> logAddToCart(int id, String name, double price) async {
    await logEvent('add_to_cart', parameters: {
      'item_id': id,
      'item_name': name,
      'price': price,
    });
  }

  /// Report a non-fatal error
  Future<void> reportError(dynamic error, StackTrace? stackTrace, {dynamic reason}) async {
    if (kDebugMode) {
      print('Reporting Error: $error');
      if (stackTrace != null) print(stackTrace);
    }
    // In production:
    // await FirebaseCrashlytics.instance.recordError(error, stackTrace, reason: reason);
  }
}
