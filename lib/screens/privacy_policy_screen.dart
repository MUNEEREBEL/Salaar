// lib/screens/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: AppTheme.headlineMedium.copyWith(color: AppTheme.whiteColor),
        ),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.whiteColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '1. Information We Collect',
              [
                'Personal Information: Name, email address, username, and profile information you provide during registration.',
                'Location Data: GPS coordinates and location information when you report issues or use location-based features.',
                'Device Information: Device type, operating system, app version, and unique device identifiers.',
                'Usage Data: How you interact with the app, features used, and performance data.',
                'Content Data: Reports, photos, comments, and other content you submit through the app.',
                'Communication Data: Messages and communications between users, workers, and administrators.',
              ],
            ),
            _buildSection(
              '2. How We Use Your Information',
              [
                'To provide and maintain the SALAAR app services.',
                'To process and manage civic issue reports and assignments.',
                'To enable communication between users, workers, and administrators.',
                'To provide location-based services and routing for workers.',
                'To improve app functionality and user experience.',
                'To send important updates and notifications about your reports.',
                'To maintain security and prevent fraud.',
                'To comply with legal obligations and enforce our terms.',
              ],
            ),
            _buildSection(
              '3. Information Sharing',
              [
                'We do not sell, trade, or rent your personal information to third parties.',
                'We may share information with authorized workers and administrators to process your reports.',
                'We may share aggregated, anonymized data for research and improvement purposes.',
                'We may disclose information if required by law or to protect our rights and safety.',
                'We may share information with service providers who assist in app operations.',
              ],
            ),
            _buildSection(
              '4. Data Security',
              [
                'We implement industry-standard security measures to protect your data.',
                'All data transmission is encrypted using SSL/TLS protocols.',
                'We use secure cloud infrastructure (Supabase) for data storage.',
                'Access to personal data is restricted to authorized personnel only.',
                'We regularly audit our security practices and update them as needed.',
              ],
            ),
            _buildSection(
              '5. Location Data',
              [
                'We collect location data to provide accurate issue reporting and worker routing.',
                'Location data is used only for legitimate app functionality.',
                'You can disable location services, but some features may not work properly.',
                'Location data is stored securely and not shared with unauthorized parties.',
                'We retain location data only as long as necessary for app functionality.',
              ],
            ),
            _buildSection(
              '6. Data Retention',
              [
                'We retain your personal information as long as your account is active.',
                'Report data may be retained for administrative and legal purposes.',
                'You can request deletion of your data by contacting us.',
                'Some data may be retained longer if required by law.',
                'Anonymized data may be retained indefinitely for research purposes.',
              ],
            ),
            _buildSection(
              '7. Your Rights',
              [
                'Access: You can request access to your personal data.',
                'Correction: You can update or correct your information.',
                'Deletion: You can request deletion of your account and data.',
                'Portability: You can request a copy of your data.',
                'Objection: You can object to certain data processing activities.',
                'Withdrawal: You can withdraw consent for data processing.',
              ],
            ),
            _buildSection(
              '8. Third-Party Services',
              [
                'We use Supabase for backend services and data storage.',
                'We use Google services for authentication and maps.',
                'We use Geoapify for mapping and geocoding services.',
                'We use OpenAI for AI-powered features.',
                'These services have their own privacy policies and data practices.',
              ],
            ),
            _buildSection(
              '9. Children\'s Privacy',
              [
                'Our app is not intended for children under 13 years of age.',
                'We do not knowingly collect personal information from children under 13.',
                'If we discover we have collected data from a child under 13, we will delete it immediately.',
                'Parents should monitor their children\'s use of the app.',
              ],
            ),
            _buildSection(
              '10. Changes to Privacy Policy',
              [
                'We may update this privacy policy from time to time.',
                'We will notify you of significant changes through the app or email.',
                'Your continued use of the app constitutes acceptance of the updated policy.',
                'We encourage you to review this policy periodically.',
              ],
            ),
            _buildSection(
              '11. Contact Information',
              [
                'For privacy-related questions or concerns, contact us at:',
                'Email: privacy@salaar.com',
                'Phone: +91 8328330168',
                'Address: SALAAR Development Team, India',
                'We will respond to your inquiry within 48 hours.',
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Text(
                'Last Updated: ${DateTime.now().toString().split(' ')[0]}\n\nBy using the SALAAR app, you agree to this Privacy Policy. If you do not agree, please do not use the app.',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.whiteColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<String> points) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTheme.titleLarge.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...points.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(top: 8, right: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    point,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.whiteColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
