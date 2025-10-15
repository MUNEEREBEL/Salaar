// lib/screens/citizen/profile_screen_fixed.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider_complete.dart';
import '../../theme/app_theme.dart';
import '../../services/level_up_analytics_service.dart';
import '../../services/comprehensive_permission_service.dart';
import '../../services/account_deletion_service.dart';
import '../../services/work_statistics_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../team_details_screen.dart';
import '../privacy_policy_screen.dart';
import '../rating_screen.dart';
import '../../services/notification_service.dart';
import 'notifications_screen.dart';
import '../settings_screen.dart';

class ProfileScreenFixed extends StatefulWidget {
  const ProfileScreenFixed({Key? key}) : super(key: key);

  @override
  State<ProfileScreenFixed> createState() => _ProfileScreenFixedState();
}

class _ProfileScreenFixedState extends State<ProfileScreenFixed> {
  WorkStatistics? _workStatistics;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadWorkStatistics();
  }

  Future<void> _loadWorkStatistics() async {
    final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
    if (authProvider.currentUser != null) {
      try {
        final stats = await WorkStatisticsService.calculateWorkStatistics(authProvider.currentUser!.id);
        setState(() {
          _workStatistics = stats;
          _isLoadingStats = false;
        });
      } catch (e) {
        print('Error loading work statistics: $e');
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderComplete>(context);

    if (authProvider.isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryColor),
              const SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: AppTheme.bodyLarge.copyWith(color: AppTheme.whiteColor),
              ),
            ],
          ),
        ),
      );
    }

    final user = authProvider.currentUser!;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh user profile data and work statistics
          final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
          try {
            // Reload user data from Supabase
            await authProvider.reloadUser();
            // Reload work statistics
            await _loadWorkStatistics();
            // Small delay for smooth animation
            await Future.delayed(Duration(milliseconds: 500));
          } catch (e) {
            print('Error refreshing profile: $e');
          }
        },
        child: CustomScrollView(
          slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.darkBackground,
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationsScreen(),
                    ),
                  );
                },
                icon: Icon(
                  Icons.notifications_outlined,
                  color: AppTheme.whiteColor,
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.settings, color: AppTheme.whiteColor),
                tooltip: 'Settings',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.8),
                      AppTheme.secondaryColor.withOpacity(0.6),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: AppTheme.whiteColor.withOpacity(0.2),
                              backgroundImage: user.profileImageUrl != null 
                                  ? NetworkImage(user.profileImageUrl!)
                                  : null,
                              child: user.profileImageUrl == null
                                  ? Text(
                                      (user.fullName ?? user.username ?? 'U').substring(0, 1).toUpperCase(),
                                      style: TextStyle(
                                        color: AppTheme.whiteColor,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.fullName ?? user.username ?? 'User',
                                    style: AppTheme.headlineMedium.copyWith(
                                      color: AppTheme.whiteColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '@${user.username}',
                                    style: AppTheme.bodyLarge.copyWith(
                                      color: AppTheme.whiteColor.withOpacity(0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.whiteColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _isLoadingStats ? 'Loading...' : WorkStatisticsService.getLevelName(_workStatistics?.level ?? 1),
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.whiteColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _editProfile,
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.whiteColor.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.edit,
                                  color: AppTheme.whiteColor,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Profile Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Stats Cards
                  _buildStatsSection(user),
                  const SizedBox(height: 24),

                  // Profile Information
                  _buildProfileInfoSection(user),
                  const SizedBox(height: 24),

                  // Quick Actions
                  _buildQuickActionsSection(),
                  const SizedBox(height: 24),

                  // App Information
                  _buildAppInfoSection(),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(user) {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Your Progress',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Level',
                    _isLoadingStats ? '...' : (_workStatistics?.level ?? 1).toString(),
                    Icons.star,
                    AppTheme.accentColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'XP',
                    _isLoadingStats ? '...' : (_workStatistics?.xpPoints ?? 0).toString(),
                    Icons.bolt,
                    AppTheme.primaryColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Reports',
                    _isLoadingStats ? '...' : (_workStatistics?.totalReports ?? 0).toString(),
                    Icons.assignment,
                    AppTheme.successColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Completed',
                    _isLoadingStats ? '...' : (_workStatistics?.completedReports ?? 0).toString(),
                    Icons.verified,
                    AppTheme.secondaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Analytics Section
            _buildAnalyticsSection(user),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsSection(user) {
    if (_isLoadingStats || _workStatistics == null) {
      return Card(
        color: AppTheme.darkSurface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
        ),
      );
    }

    final stats = _workStatistics!;
    final totalReports = stats.totalReports;
    final completedReports = stats.completedReports;
    final verifiedReports = stats.verifiedReports;
    final pendingReports = stats.pendingReports;
    final currentLevel = stats.level;
    final levelName = WorkStatisticsService.getLevelName(currentLevel);
    final expToNext = WorkStatisticsService.getXPNeededForNextLevel(stats.xpPoints, currentLevel);
    final levelProgress = WorkStatisticsService.getXPProgress(stats.xpPoints, currentLevel);
    final totalXPForLevel = WorkStatisticsService.getXPForNextLevel(currentLevel) - 
                           (currentLevel == 1 ? 0 : WorkStatisticsService.getXPForNextLevel(currentLevel - 1));
    final progressPercentage = totalXPForLevel > 0 ? (levelProgress / totalXPForLevel * 100).clamp(0, 100).toDouble() : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Level & Analytics',
          style: AppTheme.titleMedium.copyWith(
            color: AppTheme.whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Level Progress Card
        Card(
          color: AppTheme.darkSurface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level $currentLevel - $levelName',
                      style: AppTheme.titleMedium.copyWith(
                        color: AppTheme.whiteColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${stats.xpPoints} XP',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progressPercentage / 100,
                  backgroundColor: AppTheme.darkBackground,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
                const SizedBox(height: 4),
                Text(
                  expToNext > 0 ? '$expToNext XP to next level' : 'Max level reached!',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.greyColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        Text(
          'Report Analytics',
          style: AppTheme.titleMedium.copyWith(
            color: AppTheme.whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        // Simple bar chart representation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildChartBar('Solved', verifiedReports, AppTheme.successColor, totalReports),
            _buildChartBar('Pending', pendingReports, AppTheme.accentColor, totalReports),
            _buildChartBar('Total', totalReports, AppTheme.primaryColor, totalReports),
          ],
        ),
        const SizedBox(height: 12),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem('Solved', AppTheme.successColor, verifiedReports),
            _buildLegendItem('Pending', AppTheme.accentColor, pendingReports),
            _buildLegendItem('Total', AppTheme.primaryColor, totalReports),
          ],
        ),
      ],
    );
  }

  Widget _buildChartBar(String label, int value, Color color, int maxValue) {
    final height = maxValue > 0 ? (value / maxValue * 40).clamp(8.0, 40.0) : 8.0;
    
    return Column(
      children: [
        Container(
          width: 20,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.greyColor,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$value',
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.whiteColor,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTheme.titleLarge.copyWith(
            color: AppTheme.whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.greyColor,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileInfoSection(user) {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Profile Information',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Email', user.email, Icons.email),
            _buildInfoRow('Username', '@${user.username}', Icons.person),
            _buildInfoRow('Role', user.role.toUpperCase(), Icons.verified_user),
            if (user.bio != null) _buildInfoRow('Bio', user.bio!, Icons.info),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.greyColor,
                  ),
                ),
                Text(
                  value,
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionTile(
              'Rate App',
              'Help us improve',
              Icons.star,
              AppTheme.accentColor,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RatingScreen()),
                );
              },
            ),
            _buildActionTile(
              'Our Team',
              'Meet the developers',
              Icons.people,
              AppTheme.secondaryColor,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const TeamDetailsScreen()),
                );
              },
            ),
            _buildActionTile(
              'Privacy Policy',
              'Read our privacy policy',
              Icons.privacy_tip,
              Colors.purple,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: AppTheme.titleMedium.copyWith(
          color: AppTheme.whiteColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.bodySmall.copyWith(
          color: AppTheme.greyColor,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: AppTheme.greyColor,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Widget _buildAppInfoSection() {
    return Card(
      color: AppTheme.darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    ),
                  ),
                  child: Icon(
                    Icons.verified_user,
                    color: AppTheme.whiteColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SALAAR',
                        style: AppTheme.titleLarge.copyWith(
                          color: AppTheme.whiteColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Version 1.0.0',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.greyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {
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
                  icon: Icon(Icons.info, color: AppTheme.primaryColor),
                  label: Text('About', style: TextStyle(color: AppTheme.primaryColor)),
                ),
                TextButton.icon(
                  onPressed: () {
                    _showSignOutDialog();
                  },
                  icon: Icon(Icons.logout, color: AppTheme.errorColor),
                  label: Text('Sign Out', style: TextStyle(color: AppTheme.errorColor)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editProfile() {
    // Prevent multiple dialogs
    if (Navigator.of(context).canPop()) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _EditProfileDialog(),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Sign Out',
          style: TextStyle(color: AppTheme.whiteColor),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppTheme.greyColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppTheme.greyColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProviderComplete>(context, listen: false).signOut();
            },
            child: Text('Sign Out', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Settings',
          style: TextStyle(color: AppTheme.whiteColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.notifications, color: AppTheme.primaryColor),
              title: Text('Notifications', style: TextStyle(color: AppTheme.whiteColor)),
              subtitle: Text('Manage notification preferences', style: TextStyle(color: AppTheme.greyColor)),
              onTap: () {
                Navigator.pop(context);
                _showNotificationSettings();
              },
            ),
            ListTile(
              leading: Icon(Icons.dark_mode, color: AppTheme.secondaryColor),
              title: Text('Theme', style: TextStyle(color: AppTheme.whiteColor)),
              subtitle: Text('Change app appearance', style: TextStyle(color: AppTheme.greyColor)),
              onTap: () {
                Navigator.pop(context);
                _showThemeSettings();
              },
            ),
            ListTile(
              leading: Icon(Icons.language, color: AppTheme.accentColor),
              title: Text('Language', style: TextStyle(color: AppTheme.whiteColor)),
              subtitle: Text('Select your preferred language', style: TextStyle(color: AppTheme.greyColor)),
              onTap: () {
                Navigator.pop(context);
                _showLanguageSettings();
              },
            ),
            ListTile(
              leading: Icon(Icons.storage, color: Colors.orange),
              title: Text('Storage', style: TextStyle(color: AppTheme.whiteColor)),
              subtitle: Text('Manage app storage', style: TextStyle(color: AppTheme.greyColor)),
              onTap: () {
                Navigator.pop(context);
                _showStorageSettings();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text('Notification Settings', style: TextStyle(color: AppTheme.whiteColor)),
        content: Text('Notification settings will be available soon!', style: TextStyle(color: AppTheme.greyColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showThemeSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text('Theme Settings', style: TextStyle(color: AppTheme.whiteColor)),
        content: Text('Theme settings will be available soon!', style: TextStyle(color: AppTheme.greyColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showLanguageSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text('Language Settings', style: TextStyle(color: AppTheme.whiteColor)),
        content: Text('Language settings will be available soon!', style: TextStyle(color: AppTheme.greyColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showStorageSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text('Storage Settings', style: TextStyle(color: AppTheme.whiteColor)),
        content: Text('Storage settings will be available soon!', style: TextStyle(color: AppTheme.greyColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      final result = await AccountDeletionService.deleteCurrentUserAccount();
      
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        // Navigate to auth screen
        Navigator.pushReplacementNamed(context, '/auth');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete account: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}

class _EditProfileDialog extends StatefulWidget {
  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isLoading = false;
  File? _profileImage;
  File? _backgroundImage;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
    final user = authProvider.currentUser;
    _nameController.text = user?.fullName ?? '';
    _bioController.text = user?.bio ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, {bool isProfile = true}) async {
    try {
      final hasPermission = await ComprehensivePermissionService.hasStoragePermission();
      if (!hasPermission) {
        final granted = await ComprehensivePermissionService.requestStoragePermission();
        if (!granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permission required to access gallery'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
          return;
        }
      }

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          if (isProfile) {
            _profileImage = File(image.path);
          } else {
            _backgroundImage = File(image.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<String?> _uploadImageToSupabase(File image, String type) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${user.id}_${type}_$timestamp.jpg';
      
      // Upload to issue-images bucket
      await Supabase.instance.client.storage
          .from('issue-images')
          .upload(fileName, image);
      
      // Get public URL
      return Supabase.instance.client.storage
          .from('issue-images')
          .getPublicUrl(fileName);
    } catch (e) {
      print('Error uploading image to Supabase: $e');
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
      final user = authProvider.currentUser;
      
      if (user != null) {
        // Prepare update data
        Map<String, dynamic> updateData = {
          'full_name': _nameController.text,
          'bio': _bioController.text,
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Upload images to Supabase Storage if selected
        if (_profileImage != null) {
          try {
            final profileImageUrl = await _uploadImageToSupabase(_profileImage!, 'profile');
            if (profileImageUrl != null) {
              updateData['profile_image_url'] = profileImageUrl;
            }
          } catch (e) {
            print('Error uploading profile image: $e');
          }
        }
        
        if (_backgroundImage != null) {
          try {
            final backgroundImageUrl = await _uploadImageToSupabase(_backgroundImage!, 'background');
            if (backgroundImageUrl != null) {
              updateData['background_image_url'] = backgroundImageUrl;
            }
          } catch (e) {
            print('Error uploading background image: $e');
          }
        }
        
        // Update profile in Supabase
        await Supabase.instance.client.from('profiles').update(updateData).eq('id', user.id);
        
        // Refresh user data - trigger rebuild after dialog closes
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            authProvider.notifyListeners();
          });
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('Profile update error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.darkSurface,
      title: Text(
        'Edit Profile',
        style: TextStyle(color: AppTheme.whiteColor),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile Image Section
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryColor, width: 3),
                ),
                child: ClipOval(
                  child: _profileImage != null
                      ? Image.file(_profileImage!, fit: BoxFit.cover)
                      : Container(
                          color: AppTheme.darkBackground,
                          child: Icon(
                            Icons.person,
                            size: 60,
                            color: AppTheme.greyColor,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera, isProfile: true),
                    icon: Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                    label: Text('Camera', style: TextStyle(color: AppTheme.primaryColor)),
                  ),
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery, isProfile: true),
                    icon: Icon(Icons.photo_library, color: AppTheme.primaryColor),
                    label: Text('Gallery', style: TextStyle(color: AppTheme.primaryColor)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Background Image Section
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.primaryColor, width: 2),
                ),
                child: _backgroundImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(_backgroundImage!, fit: BoxFit.cover),
                      )
                    : Container(
                        color: AppTheme.darkBackground,
                        child: Center(
                          child: Text(
                            'Background Image',
                            style: TextStyle(color: AppTheme.greyColor),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera, isProfile: false),
                    icon: Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                    label: Text('Camera', style: TextStyle(color: AppTheme.primaryColor)),
                  ),
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery, isProfile: false),
                    icon: Icon(Icons.photo_library, color: AppTheme.primaryColor),
                    label: Text('Gallery', style: TextStyle(color: AppTheme.primaryColor)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Name Field
              TextFormField(
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
                style: TextStyle(color: AppTheme.whiteColor),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: AppTheme.darkBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Bio Field
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                style: TextStyle(color: AppTheme.whiteColor),
                decoration: InputDecoration(
                  labelText: 'Bio (Optional)',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: AppTheme.darkBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppTheme.greyColor),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.whiteColor),
                  ),
                )
              : Text(
                  'Save',
                  style: TextStyle(color: AppTheme.whiteColor),
                ),
        ),
      ],
    );
  }
}
