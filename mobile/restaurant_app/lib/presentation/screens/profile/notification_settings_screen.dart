import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _orderUpdates = true;
  bool _promotions = true;
  bool _loyaltyReward = true;
  bool _newMenu = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('notification_settings')),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                context.tr('notification_prefs_desc'),
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                ),
              ),
            ),
            _buildSwitchTile(
              context,
              title: context.tr('order_status_updates'),
              subtitle: context.tr('order_status_updates_desc'),
              value: _orderUpdates,
              onChanged: (val) => setState(() => _orderUpdates = val),
            ),
            const Divider(),
            _buildSwitchTile(
              context,
              title: context.tr('promotions_offers'),
              subtitle: context.tr('promotions_offers_desc'),
              value: _promotions,
              onChanged: (val) => setState(() => _promotions = val),
            ),
            const Divider(),
            _buildSwitchTile(
              context,
              title: context.tr('loyalty_rewards_notif'),
              subtitle: context.tr('loyalty_rewards_notif_desc'),
              value: _loyaltyReward,
              onChanged: (val) => setState(() => _loyaltyReward = val),
            ),
            const Divider(),
            _buildSwitchTile(
              context,
              title: context.tr('new_menu_items'),
              subtitle: context.tr('new_menu_items_desc'),
              value: _newMenu,
              onChanged: (val) => setState(() => _newMenu = val),
            ),
            const SizedBox(height: 40),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: () {
                    // Save preferences in real app
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.tr('settings_saved'))),
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                  ),
                  child: Text(context.tr('save_settings')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryColor,
    );
  }
}
