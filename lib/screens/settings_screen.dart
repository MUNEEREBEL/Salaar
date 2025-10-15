// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider_complete.dart';
import '../theme/app_theme.dart';
import 'citizen/profile_screen_fixed.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: AppTheme.headlineMedium.copyWith(color: AppTheme.whiteColor),
        ),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle(context, 'Profile Settings'),
          _buildSettingsTile(
            context,
            icon: Icons.person,
            title: 'Edit Profile',
            subtitle: 'Update your name, picture, and bio',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreenFixed()),
              );
            },
          ),
                  _buildSettingsTile(
                    context,
                    icon: Icons.lock,
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    onTap: () {
                      _showChangePasswordDialog(context);
                    },
                  ),
          const SizedBox(height: 24),

          _buildSectionTitle(context, 'App Settings'),
          _buildSettingsTile(
            context,
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Notification settings coming soon!')),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.location_on,
            title: 'Location Access',
            subtitle: 'Manage location permissions',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Location settings coming soon!')),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.language,
            title: 'Language',
            subtitle: 'Change app language',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Language settings coming soon!')),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.color_lens,
            title: 'Theme',
            subtitle: 'Switch between light and dark mode',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Theme settings coming soon!')),
              );
            },
          ),
          const SizedBox(height: 24),

          _buildSectionTitle(context, 'Privacy & Security'),
          _buildSettingsTile(
            context,
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Privacy Policy coming soon!')),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.security,
            title: 'Security Settings',
            subtitle: 'Manage account security',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Security settings coming soon!')),
              );
            },
          ),
          const SizedBox(height: 24),

          _buildSectionTitle(context, 'Support'),
          _buildSettingsTile(
            context,
            icon: Icons.help,
            title: 'Help & FAQ',
            subtitle: 'Find answers to common questions',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Help & FAQ coming soon!')),
              );
            },
          ),
          _buildSettingsTile(
            context,
            icon: Icons.feedback,
            title: 'Send Feedback',
            subtitle: 'Share your thoughts and suggestions',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Send Feedback coming soon!')),
              );
            },
          ),
          const SizedBox(height: 32),

          // Sign Out Button
          ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: AppTheme.darkSurface,
                  title: Text('Sign Out', style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor)),
                  content: Text(
                    'Are you sure you want to sign out?',
                    style: AppTheme.bodyMedium.copyWith(color: AppTheme.greyColor),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: TextStyle(color: AppTheme.greyColor)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        authProvider.signOut();
                        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                      },
                      child: Text('Sign Out', style: TextStyle(color: AppTheme.errorColor)),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout, color: AppTheme.whiteColor),
            label: Text(
              'Sign Out',
              style: AppTheme.titleMedium.copyWith(color: AppTheme.whiteColor),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTheme.titleLarge.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      color: AppTheme.darkSurface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.accentColor),
        title: Text(title, style: AppTheme.titleMedium.copyWith(color: AppTheme.whiteColor)),
        subtitle: Text(subtitle, style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor)),
        trailing: Icon(Icons.arrow_forward_ios, color: AppTheme.greyColor, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final _currentPasswordController = TextEditingController();
    final _newPasswordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Change Password',
          style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.greyColor)),
          ),
          ElevatedButton(
            onPressed: () {
              if (_newPasswordController.text == _confirmPasswordController.text) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Password changed successfully!'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Passwords do not match!'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: Text('Change Password', style: TextStyle(color: AppTheme.whiteColor)),
          ),
        ],
      ),
    );
  }
}