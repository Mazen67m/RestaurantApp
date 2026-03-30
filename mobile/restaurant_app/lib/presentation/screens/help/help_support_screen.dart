import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('help_support')),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildFAQItem(
              'How can I track my order?',
              'You can track your order in real-time by going to the "Orders" tab and clicking on your active order.',
            ),
            _buildFAQItem(
              'How long does delivery take?',
              'Delivery usually takes between 30 to 45 minutes depending on your location and the current branch traffic.',
            ),
            _buildFAQItem(
              'What payment methods are available?',
              'We currently support Cash on Delivery and Credit/Debit cards.',
            ),
            _buildFAQItem(
              'Can I cancel my order?',
              'Orders can be cancelled within 5 minutes of placement. After that, please contact the branch directly.',
            ),
            const SizedBox(height: 40),
            const Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildContactMethod(
              context,
              Icons.phone_outlined,
              'Call Us',
              '19xxx (Local Support)',
            ),
            _buildContactMethod(
              context,
              Icons.email_outlined,
              'Email Support',
              'support@restaurantapp.com',
            ),
            _buildContactMethod(
              context,
              Icons.chat_bubble_outline,
              'Live Chat',
              'Available 24/7',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ),
      ],
      tilePadding: EdgeInsets.zero,
      expandedAlignment: Alignment.topLeft,
      shape: const RoundedRectangleBorder(),
    );
  }

  Widget _buildContactMethod(BuildContext context, IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
