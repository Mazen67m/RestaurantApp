import 'package:flutter/material.dart';
import '../features/onboarding/presentation/screens/splash_screen.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/onboarding/presentation/screens/force_update_screen.dart';
import '../features/onboarding/presentation/screens/select_language_screen.dart';
import '../features/onboarding/presentation/screens/location_access_screen.dart';
import '../features/onboarding/presentation/screens/welcome_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/otp_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String forceUpdate = '/force-update';
  static const String selectLanguage = '/select-language';
  static const String locationAccess = '/location-access';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    onboarding: (context) => const OnboardingScreen(),
    forceUpdate: (context) => const ForceUpdateScreen(),
    selectLanguage: (context) => const SelectLanguageScreen(),
    locationAccess: (context) => const LocationAccessScreen(),
    welcome: (context) => const WelcomeScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    otp: (context) => const OtpVerificationScreen(),
  };
}
