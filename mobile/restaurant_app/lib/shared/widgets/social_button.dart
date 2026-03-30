import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

class SocialButton extends StatelessWidget {
  final String type; // 'google' or 'apple'
  final VoidCallback onPressed;

  const SocialButton({
    super.key,
    required this.type,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isGoogle = type.toLowerCase() == 'google';
    
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.l),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.l),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Use icons or text for labels if SVG not available
              Icon(
                isGoogle ? Icons.g_mobiledata : Icons.apple,
                size: 24,
                color: Colors.white,
              ),
              const SizedBox(width: AppSpacing.s),
              Text(
                isGoogle ? 'Google' : 'Apple',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
