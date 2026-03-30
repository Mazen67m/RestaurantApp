import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/secondary_button.dart';

class AppUpdateScreen extends StatelessWidget {
  final bool isForceUpdate;
  final String? storeUrl;

  const AppUpdateScreen({
    Key? key,
    this.isForceUpdate = true,
    this.storeUrl,
  }) : super(key: key);

  Future<void> _launchStoreUrl() async {
    if (storeUrl != null && await canLaunchUrl(Uri.parse(storeUrl!))) {
      await launchUrl(Uri.parse(storeUrl!), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prevent back button
    return PopScope(
      canPop: !isForceUpdate,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Icon or Image
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    size: 80,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Update Required',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'A new version of the app is available. Please update to continue using the app within the best experience.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                PrimaryButton(
                  text: 'Update Now',
                  onPressed: _launchStoreUrl,
                ),
                if (!isForceUpdate) ...[
                  const SizedBox(height: 16),
                  SecondaryButton(
                    text: 'Later',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
