import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/social_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Login', style: TextStyle(fontSize: 16)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xxl),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Welcome Back',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sign in to continue your order.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
            const AppTextField(
              label: 'Email or Phone',
              hint: 'john.doe@mail',
              prefixIcon: Icons.email_outlined,
            ),
            const SizedBox(height: AppSpacing.l),
            const AppTextField(
              label: 'Password',
              hint: '••••••••••••',
              isPassword: true,
              prefixIcon: Icons.lock_outline,
            ),
            const SizedBox(height: AppSpacing.m),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text('Forgot Password?', style: TextStyle(color: AppColors.primary, fontSize: 13)),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              text: 'Login',
              onPressed: () {},
            ),
            const SizedBox(height: AppSpacing.xxl),
            const Row(
              children: [
                Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: TextStyle(fontSize: 10, color: AppColors.textHint)),
                ),
                Expanded(child: Divider(color: AppColors.border)),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                SocialButton(type: 'google', onPressed: () {}),
                const SizedBox(width: AppSpacing.m),
                SocialButton(type: 'apple', onPressed: () {}),
              ],
            ),
            const SizedBox(height: AppSpacing.xxxl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account?", style: TextStyle(color: AppColors.textSecondary)),
                TextButton(
                  onPressed: () {},
                  child: const Text('Sign up', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
