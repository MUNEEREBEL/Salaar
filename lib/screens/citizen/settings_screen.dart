// lib/screens/citizen/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider_complete.dart';
import '../../theme/app_theme.dart';
import '../team_details_screen.dart';
import '../privacy_policy_screen.dart';
import '../rating_screen.dart';
import '../settings/permission_management_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProviderComplete>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            color: Theme.of(context).textTheme.headlineMedium?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Section
          _buildSectionHeader(context, 'Appearance'),
          _buildThemeToggle(context, themeProvider),
          
          const SizedBox(height: 24),
          
          // Notifications Section
          _buildSectionHeader(context, 'Notifications'),
          _buildNotificationSettings(context),
          
          const SizedBox(height: 24),
          
          // Privacy & Permissions Section
          _buildSectionHeader(context, 'Privacy & Permissions'),
          _buildPermissionSettings(context),
          
          const SizedBox(height: 24),
          
          // Account Section
          _buildSectionHeader(context, 'Account'),
          _buildAccountSettings(context, authProvider),
          
          const SizedBox(height: 24),
          
          // About Section
          _buildSectionHeader(context, 'About'),
          _buildAboutSettings(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.headlineMedium?.color,
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context, ThemeProvider themeProvider) {
    return Card(
      color: Theme.of(context).cardColor,
      child: ListTile(
        leading: Icon(
          themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
          color: AppTheme.primaryColor,
        ),
        title: Text(
          'Theme',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        trailing: Switch(
          value: themeProvider.isDarkMode,
          onChanged: (value) => themeProvider.toggleTheme(),
          activeTrackColor: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildNotificationSettings(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.notifications, color: AppTheme.primaryColor),
            title: Text(
              'Push Notifications',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Receive updates about your reports',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            trailing: Switch(
              value: true,
              onChanged: (value) {},
              activeTrackColor: AppTheme.primaryColor,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.email, color: AppTheme.primaryColor),
            title: Text(
              'Email Notifications',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Get email updates',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            trailing: Switch(
              value: false,
              onChanged: (value) {},
              activeTrackColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettings(BuildContext context, AuthProviderComplete authProvider) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.person, color: AppTheme.primaryColor),
            title: Text(
              'Profile',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Manage your profile information',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            onTap: () {
              // Navigate to profile screen
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.security, color: AppTheme.primaryColor),
            title: Text(
              'Privacy & Security',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Manage your privacy settings',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            onTap: () {
              // Navigate to privacy settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSettings(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.star, color: AppTheme.accentColor),
            title: Text(
              'Rate App',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Help us improve by rating the app',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RatingScreen()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.people, color: AppTheme.primaryColor),
            title: Text(
              'Our Team',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Meet the SALAAR development team',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TeamDetailsScreen()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.privacy_tip, color: AppTheme.primaryColor),
            title: Text(
              'Privacy Policy',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Read our privacy policy',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.info, color: AppTheme.primaryColor),
            title: Text(
              'About SALAAR',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'SALAAR',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2024 SALAAR Team',
                children: [
                  Text('Developed by: Muneer Shaik, Sai Kiran Gidugu, Satya Charan Sankuratri, Rahul Mrithpati'),
                  const SizedBox(height: 16),
                  Text('SALAAR - Transforming civic governance through technology'),
                ],
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.logout, color: AppTheme.errorColor),
            title: Text(
              'Sign Out',
              style: TextStyle(
                color: AppTheme.errorColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              _showSignOutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionSettings(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.security, color: AppTheme.primaryColor),
            title: Text(
              'Permission Management',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              'Manage app permissions and privacy settings',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              size: 16,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PermissionManagementScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Sign Out',
          style: TextStyle(
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProviderComplete>(context, listen: false).signOut();
            },
            child: Text(
              'Sign Out',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
