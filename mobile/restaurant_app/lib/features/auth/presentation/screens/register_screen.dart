import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/social_button.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Log In', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Create Account',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Join us for a premium dining experience and exclusive rewards.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const AppTextField(
              label: 'Full Name',
              hint: 'Enter your full name',
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: AppSpacing.l),
            const AppTextField(
              label: 'Email Address',
              hint: 'name@example.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: AppSpacing.l),
            const AppTextField(
              label: 'Phone Number',
              hint: '+1 (555) 000-0000',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: AppSpacing.l),
            const AppTextField(
              label: 'Password',
              hint: 'Create a password',
              isPassword: true,
              prefixIcon: Icons.lock_outline,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Checkbox(value: false, onChanged: (v) {}, activeColor: AppColors.primary),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(text: 'Terms of Service', style: TextStyle(color: AppColors.primary)),
                        const TextSpan(text: ' and '),
                        TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppColors.primary)),
                        const TextSpan(text: ', including cookie use.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const Row(
              children: [
                Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR CONTINUE WITH', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                ),
                Expanded(child: Divider(color: AppColors.border)),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                SocialButton(type: 'google', onPressed: () {}),
                const SizedBox(width: AppSpacing.m),
                SocialButton(type: 'apple', onPressed: () {}),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              text: 'Create Account',
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account?", style: TextStyle(color: AppColors.textSecondary)),
                TextButton(
                  onPressed: () {},
                  child: const Text('Log In', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
