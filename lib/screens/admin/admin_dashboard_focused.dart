import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider_complete.dart';
import '../../providers/issues_provider.dart';
import '../../theme/app_theme.dart';
import 'worker_creation_screen.dart';
import 'reports_management_modern.dart';
import 'worker_details_screen.dart';
import 'admin_profile_screen.dart';
import '../../services/admin_notification_service_fixed.dart';

class AdminDashboardFocused extends StatefulWidget {
  const AdminDashboardFocused({Key? key}) : super(key: key);

  @override
  State<AdminDashboardFocused> createState() => _AdminDashboardFocusedState();
}

class _AdminDashboardFocusedState extends State<AdminDashboardFocused> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<int> _getActiveWorkersCount() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('role', 'worker')
          .eq('is_active', true);
      return response.length;
    } catch (e) {
      print('Error getting active workers count: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: AppTheme.headlineMedium.copyWith(color: AppTheme.whiteColor),
        ),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.person, color: AppTheme.primaryColor),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AdminProfileScreen()),
              );
            },
            tooltip: 'Admin Profile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Navigation
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              border: Border(
                bottom: BorderSide(color: AppTheme.greyColor.withOpacity(0.2)),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabItem(
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    index: 0,
                  ),
                  _buildTabItem(
                    icon: Icons.assignment,
                    title: 'Reports',
                    index: 1,
                  ),
                  _buildTabItem(
                    icon: Icons.work,
                    title: 'Worker Details',
                    index: 2,
                  ),
                  _buildTabItem(
                    icon: Icons.person_add,
                    title: 'Create Worker',
                    index: 3,
                  ),
                  _buildTabItem(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    index: 4,
                  ),
                ],
              ),
            ),
          ),
          // Main Content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: [
                _buildDashboard(),                    // Index 0 - Dashboard
                const ReportsManagementModern(),      // Index 1 - Reports
                _buildWorkerDetails(),                // Index 2 - Worker Details
                _buildWorkerCreationDisabled(),       // Index 3 - Create Worker
                _buildNotifications(),                // Index 4 - Notifications
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppTheme.primaryColor : AppTheme.greyColor;
    
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: AppTheme.primaryColor, width: 1) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTheme.bodyMedium.copyWith(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return Consumer2<AuthProviderComplete, IssuesProvider>(
      builder: (context, authProvider, issuesProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, Admin!',
                      style: AppTheme.headlineLarge.copyWith(
                        color: AppTheme.whiteColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your Salaar community efficiently',
                      style: AppTheme.bodyLarge.copyWith(
                        color: AppTheme.whiteColor.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Total Reports',
                      '${issuesProvider.issues.length}',
                      Icons.assignment,
                      AppTheme.infoColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Pending Reports',
                      '${issuesProvider.issues.where((i) => i.status == 'pending').length}',
                      Icons.pending,
                      AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Completed Reports',
                      '${issuesProvider.issues.where((i) => i.status == 'completed').length}',
                      Icons.check_circle,
                      AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FutureBuilder<int>(
                      future: _getActiveWorkersCount(),
                      builder: (context, snapshot) {
                        return _buildStatCard(
                          'Active Workers',
                          '${snapshot.data ?? 0}',
                          Icons.work,
                          AppTheme.primaryColor,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: AppTheme.headlineMedium.copyWith(
                  color: AppTheme.whiteColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      'Create Worker',
                      'Add new worker account',
                      Icons.person_add,
                      () => _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickActionCard(
                      'View Reports',
                      'Manage all reports',
                      Icons.assignment,
                      () => _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: AppTheme.headlineLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.greyColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.greyColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTheme.titleMedium.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.greyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerDetails() {
    return WorkerDetailsScreen();
  }

  Widget _buildWorkerCreationDisabled() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 80,
              color: AppTheme.greyColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Worker Creation',
              style: AppTheme.headlineMedium.copyWith(
                color: AppTheme.whiteColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This option will be enabled soon!',
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.greyColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.greyColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    'Coming Soon Features:',
                    style: AppTheme.titleMedium.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Create worker accounts\n• Assign departments\n• Manage worker permissions\n• Track worker performance',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.whiteColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifications() {
    return _NotificationManagementWidget();
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Sign Out',
          style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
        ),
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
              Navigator.pop(context);
              Provider.of<AuthProviderComplete>(context, listen: false).signOut();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: Text('Sign Out', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}

class _NotificationManagementWidget extends StatefulWidget {
  @override
  State<_NotificationManagementWidget> createState() => _NotificationManagementWidgetState();
}

class _NotificationManagementWidgetState extends State<_NotificationManagementWidget> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedTarget = 'All Users';
  String _selectedType = 'info';
  bool _isSending = false;

  final List<String> _targets = ['All Users', 'Workers Only', 'Citizens Only'];
  final List<String> _types = ['info', 'success', 'warning', 'error'];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      bool success = false;
      
      switch (_selectedTarget) {
        case 'All Users':
          success = await AdminNotificationServiceFixed.sendNotificationToAll(
            title: _titleController.text,
            message: _messageController.text,
            type: _selectedType,
          );
          break;
        case 'Workers Only':
          success = await AdminNotificationServiceFixed.sendNotificationToRole(
            role: 'worker',
            title: _titleController.text,
            message: _messageController.text,
            type: _selectedType,
          );
          break;
        case 'Citizens Only':
          success = await AdminNotificationServiceFixed.sendNotificationToRole(
            role: 'citizen',
            title: _titleController.text,
            message: _messageController.text,
            type: _selectedType,
          );
          break;
      }

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification sent successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _titleController.clear();
        _messageController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send notification'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send Notifications',
            style: AppTheme.headlineMedium.copyWith(
              color: AppTheme.whiteColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            color: AppTheme.darkSurface,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Notification Title',
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(color: AppTheme.whiteColor),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    style: TextStyle(color: AppTheme.whiteColor),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedTarget,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Target Audience',
                            border: OutlineInputBorder(),
                          ),
                          items: _targets.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedTarget = newValue;
                              });
                            }
                          },
                        ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedType,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Type',
                              border: OutlineInputBorder(),
                            ),
                          items: _types.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedType = newValue;
                              });
                            }
                          },
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSending ? null : _sendNotification,
                      icon: _isSending 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.whiteColor),
                            ),
                          )
                        : Icon(Icons.send),
                      label: Text(_isSending ? 'Sending...' : 'Send Notification'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.whiteColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
