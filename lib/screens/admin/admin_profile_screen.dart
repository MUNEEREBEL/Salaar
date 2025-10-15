import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider_complete.dart';
import '../../theme/app_theme.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({Key? key}) : super(key: key);

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadProfileData() {
    final user = Provider.of<AuthProviderComplete>(context, listen: false).currentUser;
    if (user != null) {
      _nameController.text = user.fullName ?? '';
      _emailController.text = user.email ?? '';
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = Provider.of<AuthProviderComplete>(context, listen: false).currentUser;
      if (user == null) return;

      await Supabase.instance.client.from('profiles').update({
        'full_name': _nameController.text,
        'phone_number': _phoneController.text,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        setState(() {
          _isEditing = false;
        });
        
        // Refresh user data - will be updated on next app restart
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Admin Profile',
          style: AppTheme.headlineMedium.copyWith(color: AppTheme.whiteColor),
        ),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              icon: Icon(Icons.edit, color: AppTheme.primaryColor),
              tooltip: 'Edit Profile',
            )
          else
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                    });
                    _loadProfileData(); // Reset changes
                  },
                  icon: Icon(Icons.close, color: AppTheme.errorColor),
                  tooltip: 'Cancel',
                ),
                IconButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  icon: _isSaving 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.whiteColor),
                        ),
                      )
                    : Icon(Icons.save, color: AppTheme.successColor),
                  tooltip: 'Save Changes',
                ),
              ],
            ),
        ],
      ),
      body: Consumer<AuthProviderComplete>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          if (user == null) {
            return Center(
              child: Text(
                'No user data available',
                style: AppTheme.bodyLarge.copyWith(color: AppTheme.whiteColor),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.whiteColor.withOpacity(0.2),
                        child: Text(
                          (user.fullName ?? 'A').substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.whiteColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.fullName ?? 'Admin User',
                        style: AppTheme.headlineLarge.copyWith(
                          color: AppTheme.whiteColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Administrator',
                        style: AppTheme.titleMedium.copyWith(
                          color: AppTheme.whiteColor.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email ?? 'No email',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.whiteColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Profile Form
                Card(
                  color: AppTheme.darkSurface,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
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
                          const SizedBox(height: 24),

                          TextFormField(
                            controller: _nameController,
                            enabled: _isEditing,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            style: TextStyle(color: AppTheme.whiteColor),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _emailController,
                            enabled: false, // Email cannot be changed
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                            ),
                            style: TextStyle(color: AppTheme.greyColor),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _phoneController,
                            enabled: _isEditing,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            style: TextStyle(color: AppTheme.whiteColor),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value != null && value.isNotEmpty && value.length < 10) {
                                return 'Please enter a valid phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Admin Stats
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.darkCard,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin Statistics',
                                  style: AppTheme.titleMedium.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatItem(
                                        'Role',
                                        'Administrator',
                                        Icons.admin_panel_settings,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildStatItem(
                                        'Department',
                                        'Management',
                                        Icons.business,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatItem(
                                        'Account Created',
                                        'Recently',
                                        Icons.calendar_today,
                                      ),
                                    ),
                                    Expanded(
                                      child: _buildStatItem(
                                        'Status',
                                        'Active',
                                        Icons.check_circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Admin Actions
                Card(
                  color: AppTheme.darkSurface,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Actions',
                          style: AppTheme.titleLarge.copyWith(
                            color: AppTheme.whiteColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildActionTile(
                          'Change Password',
                          'Update your account password',
                          Icons.lock,
                          () {
                            // TODO: Implement change password
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Change password feature coming soon!'),
                                backgroundColor: AppTheme.infoColor,
                              ),
                            );
                          },
                        ),
                        _buildActionTile(
                          'Export Data',
                          'Export user and report data',
                          Icons.download,
                          () {
                            // TODO: Implement data export
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Data export feature coming soon!'),
                                backgroundColor: AppTheme.infoColor,
                              ),
                            );
                          },
                        ),
                        _buildActionTile(
                          'System Settings',
                          'Configure system parameters',
                          Icons.settings,
                          () {
                            // TODO: Implement system settings
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('System settings feature coming soon!'),
                                backgroundColor: AppTheme.infoColor,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.greyColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.whiteColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(
        title,
        style: AppTheme.titleMedium.copyWith(
          color: AppTheme.whiteColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.bodySmall.copyWith(
          color: AppTheme.greyColor,
        ),
      ),
      trailing: Icon(Icons.arrow_forward_ios, color: AppTheme.greyColor, size: 16),
      onTap: onTap,
    );
  }
}
