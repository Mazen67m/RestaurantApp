import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/primary_button.dart';

class MaintenanceScreen extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const MaintenanceScreen({
    Key? key,
    this.message,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.construction_rounded,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Under Maintenance',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message ??
                    'We are currently performing scheduled maintenance. We will be back shortly.',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (onRetry != null)
                PrimaryButton(
                  text: 'Retry Connection',
                  onPressed: onRetry!,
                  icon: Icons.refresh,
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
