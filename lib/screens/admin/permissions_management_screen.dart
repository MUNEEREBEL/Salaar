// lib/screens/admin/permissions_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/permissions_provider.dart';
import '../../providers/auth_provider_complete.dart';
import '../../theme/app_theme.dart';
import '../../models/permissions.dart';
import '../../models/user.dart';

class PermissionsManagementScreen extends StatefulWidget {
  const PermissionsManagementScreen({Key? key}) : super(key: key);

  @override
  State<PermissionsManagementScreen> createState() => _PermissionsManagementScreenState();
}

class _PermissionsManagementScreenState extends State<PermissionsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SalaarUser> _allUsers = [];
  List<SalaarUser> _filteredUsers = [];
  bool _isLoading = false;
  String _selectedUserId = '';

  static const List<String> _permissions = [
    'view_reports',
    'edit_reports',
    'delete_reports',
    'assign_tasks',
    'create_workers',
    'manage_users',
    'export_data',
    'view_analytics',
    'send_notifications',
    'moderate_community',
    'access_developer_tools',
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProviderComplete>(context, listen: false);
      // Load users from your existing user management
      // This is a placeholder - implement based on your user loading logic
      _allUsers = [];
      _filteredUsers = _allUsers;
    } catch (e) {
      print('Error loading users: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final name = user.fullName?.toLowerCase() ?? '';
        final email = user.email.toLowerCase();
        final searchQuery = query.toLowerCase();
        return name.contains(searchQuery) || email.contains(searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(
          'Permissions Management',
          style: AppTheme.headlineMedium.copyWith(color: AppTheme.whiteColor),
        ),
        backgroundColor: AppTheme.darkBackground,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadUsers,
            icon: Icon(Icons.refresh, color: AppTheme.primaryColor),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterUsers,
              decoration: InputDecoration(
                hintText: 'Search users by name or email...',
                prefixIcon: Icon(Icons.search, color: AppTheme.greyColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.greyColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.greyColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
              ),
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.whiteColor),
            ),
          ),
          
          // Users List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  )
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: AppTheme.greyColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: AppTheme.titleMedium.copyWith(
                                color: AppTheme.whiteColor,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = _filteredUsers[index];
                          return _buildUserCard(user);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(SalaarUser user) {
    return Card(
      color: AppTheme.darkSurface,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            (user.fullName ?? user.email).substring(0, 1).toUpperCase(),
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.whiteColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.fullName ?? 'Unknown User',
          style: AppTheme.titleMedium.copyWith(color: AppTheme.whiteColor),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.email,
              style: AppTheme.bodySmall.copyWith(color: AppTheme.greyColor),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getRoleColor(user.role).withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Text(
                user.role.toUpperCase(),
                style: AppTheme.bodySmall.copyWith(
                  color: _getRoleColor(user.role),
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          onPressed: () => _showPermissionsDialog(user),
          icon: Icon(Icons.settings, color: AppTheme.primaryColor),
          tooltip: 'Manage Permissions',
        ),
        onTap: () => _showPermissionsDialog(user),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppTheme.errorColor;
      case 'worker':
        return AppTheme.infoColor;
      case 'developer':
        return AppTheme.accentColor;
      default:
        return AppTheme.greyColor;
    }
  }

  void _showPermissionsDialog(SalaarUser user) {
    showDialog(
      context: context,
      builder: (context) => PermissionsDialog(user: user),
    );
  }
}

class PermissionsDialog extends StatefulWidget {
  final SalaarUser user;

  const PermissionsDialog({Key? key, required this.user}) : super(key: key);

  @override
  State<PermissionsDialog> createState() => _PermissionsDialogState();
}

class _PermissionsDialogState extends State<PermissionsDialog> {
  late UserPermissions _permissions;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadUserPermissions();
  }

  Future<void> _loadUserPermissions() async {
    setState(() => _isLoading = true);
    
    try {
      final permissionsProvider = Provider.of<PermissionsProvider>(context, listen: false);
      await permissionsProvider.loadUserPermissions(widget.user.id);
      
      final userPermissions = permissionsProvider.userPermissions[widget.user.id];
      if (userPermissions != null) {
        _permissions = userPermissions;
      } else {
        // Create default permissions based on role
        switch (widget.user.role.toLowerCase()) {
          case 'admin':
            _permissions = UserPermissions.getDefaultAdminPermissions(widget.user.id);
            break;
          case 'worker':
            _permissions = UserPermissions.getDefaultWorkerPermissions(widget.user.id);
            break;
          case 'developer':
            _permissions = UserPermissions.getDefaultDeveloperPermissions(widget.user.id);
            break;
          default:
            _permissions = UserPermissions.getDefaultUserPermissions(widget.user.id);
        }
      }
    } catch (e) {
      print('Error loading permissions: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updatePermission(String permission, bool value) {
    setState(() {
      _hasChanges = true;
      switch (permission) {
        case 'view_reports':
          _permissions = _permissions.copyWith(canViewReports: value);
          break;
        case 'edit_reports':
          _permissions = _permissions.copyWith(canEditReports: value);
          break;
        case 'delete_reports':
          _permissions = _permissions.copyWith(canDeleteReports: value);
          break;
        case 'assign_tasks':
          _permissions = _permissions.copyWith(canAssignTasks: value);
          break;
        case 'create_workers':
          _permissions = _permissions.copyWith(canCreateWorkers: value);
          break;
        case 'manage_users':
          _permissions = _permissions.copyWith(canManageUsers: value);
          break;
        case 'export_data':
          _permissions = _permissions.copyWith(canExportData: value);
          break;
        case 'view_analytics':
          _permissions = _permissions.copyWith(canViewAnalytics: value);
          break;
        case 'send_notifications':
          _permissions = _permissions.copyWith(canSendNotifications: value);
          break;
        case 'moderate_community':
          _permissions = _permissions.copyWith(canModerateCommunity: value);
          break;
        case 'access_developer_tools':
          _permissions = _permissions.copyWith(canAccessDeveloperTools: value);
          break;
      }
    });
  }

  bool _getPermissionValue(String permission) {
    switch (permission) {
      case 'view_reports':
        return _permissions.canViewReports;
      case 'edit_reports':
        return _permissions.canEditReports;
      case 'delete_reports':
        return _permissions.canDeleteReports;
      case 'assign_tasks':
        return _permissions.canAssignTasks;
      case 'create_workers':
        return _permissions.canCreateWorkers;
      case 'manage_users':
        return _permissions.canManageUsers;
      case 'export_data':
        return _permissions.canExportData;
      case 'view_analytics':
        return _permissions.canViewAnalytics;
      case 'send_notifications':
        return _permissions.canSendNotifications;
      case 'moderate_community':
        return _permissions.canModerateCommunity;
      case 'access_developer_tools':
        return _permissions.canAccessDeveloperTools;
      default:
        return false;
    }
  }

  Future<void> _savePermissions() async {
    setState(() => _isLoading = true);
    
    try {
      final permissionsProvider = Provider.of<PermissionsProvider>(context, listen: false);
      final success = await permissionsProvider.updateUserPermissions(
        widget.user.id,
        _permissions,
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permissions updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update permissions'),
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetToDefault() async {
    setState(() => _isLoading = true);
    
    try {
      final permissionsProvider = Provider.of<PermissionsProvider>(context, listen: false);
      final success = await permissionsProvider.resetToDefaultPermissions(widget.user.id);
      
      if (success) {
        await _loadUserPermissions();
        setState(() => _hasChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permissions reset to default!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset permissions'),
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissionsProvider = Provider.of<PermissionsProvider>(context);
    
    return AlertDialog(
      backgroundColor: AppTheme.darkSurface,
      title: Text(
        'Manage Permissions',
        style: AppTheme.titleLarge.copyWith(color: AppTheme.whiteColor),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // User Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.darkCard,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            (widget.user.fullName ?? widget.user.email)
                                .substring(0, 1)
                                .toUpperCase(),
                            style: AppTheme.titleMedium.copyWith(
                              color: AppTheme.whiteColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.user.fullName ?? 'Unknown User',
                                style: AppTheme.titleMedium.copyWith(
                                  color: AppTheme.whiteColor,
                                ),
                              ),
                              Text(
                                widget.user.email,
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.greyColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Permissions List
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _permissions.length,
                      itemBuilder: (context, index) {
                        final permission = _permissions[index];
                        final isEnabled = _getPermissionValue(permission);
                        
                        return Card(
                          color: AppTheme.darkCard,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: SwitchListTile(
                            title: Text(
                              permissionsProvider.getPermissionDisplayName(permission),
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.whiteColor,
                              ),
                            ),
                            subtitle: Text(
                              permissionsProvider.getPermissionDescription(permission),
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.greyColor,
                              ),
                            ),
                            value: isEnabled,
                            onChanged: (value) => _updatePermission(permission, value),
                            activeColor: AppTheme.primaryColor,
                            inactiveThumbColor: AppTheme.greyColor,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: _resetToDefault,
          child: Text(
            'Reset to Default',
            style: TextStyle(color: AppTheme.warningColor),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppTheme.greyColor),
          ),
        ),
        ElevatedButton(
          onPressed: _hasChanges ? _savePermissions : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
          ),
          child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: AppTheme.whiteColor,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Save Changes',
                  style: TextStyle(color: AppTheme.whiteColor),
                ),
        ),
      ],
    );
  }
}
