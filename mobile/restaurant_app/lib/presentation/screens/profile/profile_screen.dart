import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/locale_provider.dart';
import '../auth/login_screen.dart';
import '../addresses/addresses_screen.dart';
import 'edit_profile_screen.dart';
import '../loyalty/loyalty_dashboard_screen.dart';
import 'user_reviews_screen.dart';
import '../legal/terms_of_service_screen.dart';
import '../legal/privacy_policy_screen.dart';
import '../help/help_support_screen.dart';
import 'notification_settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final isArabic = localeProvider.isArabic;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(context.tr('profile'), style: const TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: authProvider.isAuthenticated
          ? _buildAuthenticatedContent(context, authProvider, localeProvider, isArabic)
          : _buildGuestContent(context),
    );
  }

  Widget _buildGuestContent(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 80,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('my_profile'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('login_to_access_profile'),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: Text(context.tr('login')),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticatedContent(
    BuildContext context,
    AuthProvider authProvider,
    LocaleProvider localeProvider,
    bool isArabic,
  ) {
    final user = authProvider.user;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  backgroundImage: user?.profileImageUrl != null
                      ? NetworkImage(user!.profileImageUrl!)
                      : null,
                  child: user?.profileImageUrl == null
                      ? Text(
                          user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user?.fullName ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Menu items
          _buildMenuItem(
            context,
            icon: Icons.person_outline,
            title: context.tr('edit_profile'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),

          _buildMenuItem(
            context,
            icon: Icons.card_giftcard,
            title: context.tr('my_loyalty'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LoyaltyDashboardScreen()),
              );
            },
          ),

          _buildMenuItem(
            context,
            icon: Icons.star_outline,
            title: context.tr('your_reviews'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const UserReviewsScreen()),
              );
            },
          ),

          _buildMenuItem(
            context,
            icon: Icons.location_on_outlined,
            title: context.tr('my_addresses'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddressesScreen()),
              );
            },
          ),

          _buildMenuItem(
            context,
            icon: Icons.language,
            title: context.tr('language'),
            trailing: Text(
              isArabic ? 'العربية' : 'English',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            onTap: () => localeProvider.toggleLocale(),
          ),

          _buildMenuItem(
            context,
            icon: Icons.notifications_outlined,
            title: context.tr('notifications'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
              );
            },
          ),

          const Divider(height: 1),

          _buildMenuItem(
            context,
            icon: Icons.help_outline,
            title: context.tr('help_support'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
              );
            },
          ),

          _buildMenuItem(
            context,
            icon: Icons.description_outlined,
            title: context.tr('terms_of_service'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
              );
            },
          ),

          _buildMenuItem(
            context,
            icon: Icons.privacy_tip_outlined,
            title: context.tr('privacy_policy'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
              );
            },
          ),

          const Divider(height: 1),

          _buildMenuItem(
            context,
            icon: Icons.logout,
            title: context.tr('logout'),
            iconColor: AppColors.error,
            titleColor: AppColors.error,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(context.tr('logout')),
                  content: Text(context.tr('logout_confirm')),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(context.tr('cancel')),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: Text(
                        context.tr('logout'),
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                await authProvider.logout();
              }
            },
          ),

          const SizedBox(height: 24),

          // App version
          Text(
            'Version 1.0.0',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    Color? iconColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppColors.textSecondary),
      title: Text(
        title,
        style: TextStyle(color: titleColor ?? Colors.white),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
