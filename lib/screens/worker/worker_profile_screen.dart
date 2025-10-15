// lib/screens/worker/worker_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider_complete.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';
import '../team_details_screen.dart';

class WorkerProfileScreen extends StatefulWidget {
  const WorkerProfileScreen({Key? key}) : super(key: key);

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  bool _isEditing = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _departmentController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _departments = [];
  String? _selectedDepartmentId;
  String _departmentName = 'No Department';
  Map<String, dynamic> _workerStats = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadDepartments();
    _loadWorkerStats();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
    final user = authProvider.currentUser;
    
    if (user != null) {
      _nameController.text = user.fullName ?? '';
      _phoneController.text = user.phoneNumber ?? '';
      _departmentController.text = user.department ?? '';
      _departmentName = user.department ?? 'No Department';
      
      // Find the department ID from the department name
      if (user.department != null && _departments.isNotEmpty) {
        final matchingDept = _departments.firstWhere(
          (dept) => dept['name'] == user.department,
          orElse: () => _departments.first,
        );
        _selectedDepartmentId = matchingDept['id'];
      } else if (_departments.isNotEmpty) {
        _selectedDepartmentId = _departments.first['id'];
      }
    }
  }

  Future<void> _loadDepartments() async {
    try {
      final response = await Supabase.instance.client
          .from('departments')
          .select('*')
          .eq('is_active', true)
          .order('name');

      if (mounted) {
        setState(() {
          _departments = List<Map<String, dynamic>>.from(response);
        });
        // Reload user data to set the correct department ID
        _loadUserData();
      }
    } catch (e) {
      print('Error loading departments: $e');
    }
  }

  Future<void> _loadWorkerStats() async {
    try {
      final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser != null) {
        // Load assigned tasks
        final assignedResponse = await Supabase.instance.client
            .from('issues')
            .select('*')
            .eq('assignee_id', currentUser.id)
            .or('status.eq.pending,status.eq.in_progress');

        // Load completed tasks
        final completedResponse = await Supabase.instance.client
            .from('issues')
            .select('*')
            .eq('assignee_id', currentUser.id)
            .eq('status', 'completed');

        // Load in progress tasks
        final inProgressResponse = await Supabase.instance.client
            .from('issues')
            .select('*')
            .eq('assignee_id', currentUser.id)
            .eq('status', 'in_progress');

        // Calculate stats
        final totalAssigned = (assignedResponse as List).length;
        final totalCompleted = (completedResponse as List).length;
        final totalInProgress = (inProgressResponse as List).length;
        final completionRate = totalAssigned > 0 ? (totalCompleted / (totalAssigned + totalCompleted)) * 100 : 0.0;

        if (mounted) {
          setState(() {
            _workerStats = {
              'assigned': totalAssigned,
              'completed': totalCompleted,
              'in_progress': totalInProgress,
              'completion_rate': completionRate,
              'total_tasks': totalAssigned + totalCompleted,
            };
          });
        }
      }
    } catch (e) {
      print('Error loading worker stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Consumer<AuthProviderComplete>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          
          if (user == null) {
            return Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadUserData();
              _loadDepartments();
              _loadWorkerStats();
              await Future.delayed(Duration(milliseconds: 500));
            },
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(user),
                  
                  // Profile Content
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Profile Information Card
                        _buildProfileInfoCard(user),
                        const SizedBox(height: 20),
                        
                        // Work Statistics Card
                        _buildWorkStatsCard(),
                        const SizedBox(height: 20),
                        
                        // Settings Card
                        _buildSettingsCard(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(SalaarUser user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.successColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          // Profile Picture
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.primaryColor,
                child: Text(
                  (user.fullName ?? 'W').substring(0, 1).toUpperCase(),
                  style: AppTheme.headlineMedium.copyWith(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.darkBackground,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.work,
                    color: AppTheme.whiteColor,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Name and Role
          Text(
            user.fullName ?? 'Worker',
            style: AppTheme.headlineMedium.copyWith(
              color: AppTheme.whiteColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Worker • $_departmentName',
            style: AppTheme.bodyLarge.copyWith(
              color: AppTheme.greyColor,
            ),
          ),
          const SizedBox(height: 20),
          
          // Edit Button
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            },
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            label: Text(_isEditing ? 'Cancel' : 'Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.whiteColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoCard(SalaarUser user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.greyColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Profile Information',
                style: AppTheme.titleLarge.copyWith(
                  color: AppTheme.whiteColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Name Field
          _buildInfoField(
            'Full Name',
            _nameController,
            Icons.person_outline,
            enabled: _isEditing,
          ),
          const SizedBox(height: 16),
          
          // Email Field (Read-only)
          _buildInfoField(
            'Email',
            TextEditingController(text: user.email ?? ''),
            Icons.email_outlined,
            enabled: false,
          ),
          const SizedBox(height: 16),
          
          // Phone Field
          _buildInfoField(
            'Phone Number',
            _phoneController,
            Icons.phone_outlined,
            enabled: _isEditing,
          ),
          const SizedBox(height: 16),
          
          // Department Field
          _buildDepartmentField(),
          
          if (_isEditing) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _loadUserData(); // Reset changes
                      });
                    },
                    child: Text('Cancel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.greyColor,
                      side: BorderSide(color: AppTheme.greyColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    child: _isLoading 
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: AppTheme.whiteColor,
                              strokeWidth: 2,
                            ),
                          )
                        : Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: AppTheme.whiteColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoField(
    String label,
    TextEditingController controller,
    IconData icon, {
    required bool enabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.greyColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.whiteColor,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.primaryColor),
            filled: true,
            fillColor: enabled ? AppTheme.darkBackground : AppTheme.darkSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.greyColor.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.greyColor.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.primaryColor,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppTheme.greyColor.withOpacity(0.1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWorkStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.greyColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: AppTheme.infoColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Work Statistics',
                style: AppTheme.titleLarge.copyWith(
                  color: AppTheme.whiteColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Tasks Assigned', '${_workerStats['assigned'] ?? 0}', Icons.assignment, AppTheme.warningColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem('Completed', '${_workerStats['completed'] ?? 0}', Icons.check_circle, AppTheme.successColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('In Progress', '${_workerStats['in_progress'] ?? 0}', Icons.hourglass_empty, AppTheme.infoColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem('Success Rate', '${(_workerStats['completion_rate'] ?? 0).toStringAsFixed(0)}%', Icons.trending_up, AppTheme.primaryColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
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
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.greyColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.greyColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: AppTheme.greyColor, size: 24),
              const SizedBox(width: 12),
              Text(
                'Settings',
                style: AppTheme.titleLarge.copyWith(
                  color: AppTheme.whiteColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildSettingItem(
            'Notifications',
            'Manage your notification preferences',
            Icons.notifications_outlined,
            () {},
          ),
          _buildSettingItem(
            'Privacy',
            'Control your privacy settings',
            Icons.privacy_tip_outlined,
            () {},
          ),
          _buildSettingItem(
            'Our Team',
            'Meet the development team',
            Icons.people_outline,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TeamDetailsScreen()),
            ),
          ),
          _buildSettingItem(
            'Help & Support',
            'Get help and contact support',
            Icons.help_outline,
            () {},
          ),
          _buildSettingItem(
            'Sign Out',
            'Sign out of your account',
            Icons.logout,
            () => _showSignOutDialog(),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDestructive 
              ? AppTheme.errorColor.withOpacity(0.1)
              : AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: AppTheme.titleMedium.copyWith(
          color: isDestructive ? AppTheme.errorColor : AppTheme.whiteColor,
          fontWeight: FontWeight.w600,
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

  void _showOurTeam() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Our Team',
          style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTeamMember(
                'Muneer Ahmed',
                'Lead Developer',
                'Full-stack developer and project lead',
                Icons.code,
              ),
              const SizedBox(height: 16),
              _buildTeamMember(
                'Salaar Team',
                'Development Team',
                'Dedicated team working on Salaar Reporter',
                Icons.people,
              ),
              const SizedBox(height: 16),
              _buildTeamMember(
                'Community',
                'Contributors',
                'Open source contributors and testers',
                Icons.favorite,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: AppTheme.greyColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMember(String name, String role, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.greyColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTheme.titleMedium.copyWith(
                    color: AppTheme.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  role,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.greyColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<AuthProviderComplete>(context, listen: false).signOut();
            },
            child: Text('Sign Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: AppTheme.whiteColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Department',
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.greyColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _isEditing ? AppTheme.darkBackground : AppTheme.darkSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.greyColor.withOpacity(0.3),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDepartmentId,
              isExpanded: true,
              dropdownColor: AppTheme.darkCard,
              style: AppTheme.bodyLarge.copyWith(
                color: AppTheme.whiteColor,
              ),
              hint: Text(
                'Select Department',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.greyColor,
                ),
              ),
              items: _departments.map((department) {
                return DropdownMenuItem<String>(
                  value: department['id'],
                  child: Text(department['name']),
                );
              }).toList(),
              onChanged: _isEditing ? (String? value) {
                setState(() {
                  _selectedDepartmentId = value;
                  if (value != null) {
                    final selectedDept = _departments.firstWhere(
                      (dept) => dept['id'] == value,
                      orElse: () => {'name': 'Unknown Department'},
                    );
                    _departmentName = selectedDept['name'] ?? 'Unknown Department';
                  }
                });
              } : null,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
      final currentUser = authProvider.currentUser;
      
      if (currentUser != null) {
        // Update profile in Supabase
        await Supabase.instance.client
            .from('profiles')
            .update({
              'full_name': _nameController.text,
              'phone_number': _phoneController.text,
              'department_id': _selectedDepartmentId,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', currentUser.id);

        // Update local profile
        await authProvider.updateProfile(
          fullName: _nameController.text,
          phoneNumber: _phoneController.text,
        );
      }
      
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
