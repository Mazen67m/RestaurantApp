import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_spacing.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to next screen after delay
    Future.delayed(const Duration(seconds: 3), () {
      // Logic to go to Onboarding or Login
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.bgGradient,
        ),
        child: Column(
          children: [
            const Spacer(flex: 3),
            // Logo Container
            Container(
              padding: const EdgeInsets.all(AppSpacing.l),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                size: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            const Text(
              'GourmetGo',
              style: AppTypography.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Deliciousness delivered',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
            const Spacer(flex: 2),
            // Loading Indicator
            const SizedBox(
              height: 40,
              width: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'VERSION 2.4.0',
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
