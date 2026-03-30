import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/primary_button.dart';

class OtpVerificationScreen extends StatelessWidget {
  const OtpVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Verify OTP', style: TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xxl),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.round),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 16),
                  SizedBox(width: 8),
                  Text('Code Verified', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const Text(
              'Enter the 4-digit code',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.s),
            const Text(
              'We’ve sent a 4-digit code to +1 (xxx) xxx-7890',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                4,
                (index) => Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.m),
                    border: Border.all(
                      color: index == 0 ? AppColors.primary : AppColors.border,
                      width: index == 0 ? 2 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    index == 0 ? '4' : '',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.round),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time_filled, color: AppColors.primary, size: 16),
                  SizedBox(width: 8),
                  Text('00:59 ', style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('REMAINING', style: TextStyle(fontSize: 12, color: AppColors.textHint)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text(
              'Didn’t receive a code?',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('Resend Code', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ),
            const Spacer(),
            PrimaryButton(
              text: 'Verify & Continue',
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
