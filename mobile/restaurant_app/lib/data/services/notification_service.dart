import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/constants.dart';
import 'api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final ApiService _apiService = ApiService();

  Future<void> initialize() async {
    // Initialize local notifications for Android
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
        if (kDebugMode) print('Notification tapped: ${details.payload}');
      },
    );

    // Create Android Notification Channel
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.high,
      );

      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    // Register token with backend if already logged in
    await registerDeviceWithBackend();
  }

  Future<String?> getToken() async {
    try {
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting FCM token: $e');
      return null;
    }
  }

  Future<void> registerDeviceWithBackend() async {
    final token = await getToken();
    if (token == null) return;

    final hasAuth = await _apiService.hasToken();
    if (!hasAuth) return;

    try {
      String deviceType = 'Unknown';
      if (kIsWeb) {
        deviceType = 'Web';
      } else {
        deviceType = defaultTargetPlatform.name;
      }

      await _apiService.post(
        ApiConstants.registerDevice,
        body: {
          'deviceToken': token,
          'deviceType': deviceType,
        },
      );
      if (kDebugMode) print('Device registered with backend: $token');
    } catch (e) {
      if (kDebugMode) print('Error registering device with backend: $e');
    }
  }

  Future<void> subscribeToTopic(String topic) async {}

  Future<void> unsubscribeFromTopic(String topic) async {}
}
