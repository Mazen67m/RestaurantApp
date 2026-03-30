import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'navigation/app_router.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/locale_provider.dart';
import 'data/providers/restaurant_provider.dart';
import 'data/providers/cart_provider.dart';
import 'data/providers/branch_provider.dart';
import 'data/providers/address_provider.dart';
import 'data/providers/connectivity_provider.dart';
import 'data/providers/order_tracking_provider.dart';
import 'data/providers/notification_provider.dart';
import 'data/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => RestaurantProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => BranchProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProxyProvider<AuthProvider, OrderTrackingProvider>(
          create: (context) => OrderTrackingProvider(
            authProvider: Provider.of<AuthProvider>(context, listen: false),
          ),
          update: (context, auth, previous) => previous!,
        ),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: const GourmetGoApp(),
    ),
  );
}

class GourmetGoApp extends StatelessWidget {
  const GourmetGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    
    return MaterialApp(
      title: 'GourmetGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: localeProvider.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      initialRoute: AppRouter.splash,
      routes: AppRouter.routes,
    );
  }
}
