import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('terms_of_service')),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              '1. Acceptance of Terms',
              'By accessing and using this application, you accept and agree to be bound by the terms and provision of this agreement. In addition, when using this application\'s particular services, you shall be subject to any posted guidelines or rules applicable to such services.',
            ),
            _buildSection(
              context,
              '2. Provision of Services',
              'You agree and acknowledge that the restaurant is entitled to modify, improve or discontinue any of its services at its sole discretion and without notice to you even if it may result in you being prevented from accessing any information contained in it.',
            ),
            _buildSection(
              context,
              '3. Proprietary Rights',
              'You acknowledge and agree that the application may contain proprietary and confidential information including trademarks, service marks and patents protected by intellectual property laws and international intellectual property treaties.',
            ),
            _buildSection(
              context,
              '4. Submitted Content',
              'When you submit content to the application you simultaneously grant the restaurant an irrevocable, worldwide, royalty free license to publish, display, modify, distribute and syndicate your content worldwide.',
            ),
            _buildSection(
              context,
              '5. Termination of Agreement',
              'The Terms of this agreement will continue to apply in perpetuity until terminated by either party without notice at any time for any reason.',
            ),
            _buildSection(
              context,
              '6. Disclaimer of Warranties',
              'You understand and agree that your use of the application is entirely at your own risk and that our services are provided "As Is" and "As Available".',
            ),
            _buildSection(
              context,
              '7. Limitation of Liability',
              'You understand and agree that the restaurant and any of its subsidiaries or affiliates shall in no event be liable for any direct, indirect, incidental, consequential, or exemplary damages.',
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
