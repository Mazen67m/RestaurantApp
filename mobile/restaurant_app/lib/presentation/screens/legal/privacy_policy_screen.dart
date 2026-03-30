import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('privacy_policy')),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              '1. Introduction',
              'We respect your privacy and are committed to protecting it through our compliance with this policy. This policy describes the types of information we may collect from you or that you may provide when you visit the Restaurant App and our practices for collecting, using, maintaining, protecting, and disclosing that information.',
            ),
            _buildSection(
              context,
              '2. Information We Collect',
              'We collect several types of information from and about users of our App, including: Personal Information (name, postal address, email address, telephone number), Information about your internet connection, the equipment you use to access our App, and usage details.',
            ),
            _buildSection(
              context,
              '3. How We Use Your Information',
              'We use information that we collect about you or that you provide to us, including any personal information: To present our App and its contents to you; To provide you with information, products, or services that you request from us; To fulfill any other purpose for which you provide it.',
            ),
            _buildSection(
              context,
              '4. Disclosure of Your Information',
              'We may disclose aggregated information about our users, and information that does not identify any individual, without restriction. We may disclose personal information that we collect to our subsidiaries and affiliates.',
            ),
            _buildSection(
              context,
              '5. Data Security',
              'We have implemented measures designed to secure your personal information from accidental loss and from unauthorized access, use, alteration, and disclosure.',
            ),
            _buildSection(
              context,
              '6. Changes to Our Privacy Policy',
              'It is our policy to post any changes we make to our privacy policy on this page. If we make material changes to how we treat our users\' personal information, we will notify you through a notice on the App home screen.',
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Last Updated: January 30, 2026',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textPrimary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
