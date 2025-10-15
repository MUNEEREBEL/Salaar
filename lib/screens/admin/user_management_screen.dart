// lib/screens/admin/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider_complete.dart';
import '../../services/admin_user_management_service.dart';
import '../../config/app_config.dart';
import '../dinosaur_loading_screen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _orphanedUsers = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hasPermissions = await AdminUserManagementService.hasUserManagementPermissions();
      if (!hasPermissions) {
        setState(() {
          _error = 'You do not have permission to manage users';
          _isLoading = false;
        });
        return;
      }

      final users = await AdminUserManagementService.listAllUsers();
      final orphanedUsers = await AdminUserManagementService.listOrphanedUsers();
      final stats = await AdminUserManagementService.getUserStats();

      if (mounted) {
        setState(() {
          _users = users;
          _orphanedUsers = orphanedUsers;
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load user data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteUser(String email) async {
    try {
      final result = await AdminUserManagementService.deleteUserSafely(email);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] ? Colors.green : Colors.red,
          ),
        );
        
        if (result['success']) {
          _loadData(); // Refresh the list
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      final result = await AdminUserManagementService.updateUserRole(
        userId: userId,
        newRole: newRole,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        
        _loadData(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderComplete>(context);
    
    if (!authProvider.isAdmin && !authProvider.isDeveloper) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
          backgroundColor: const Color(0xFF1E1E1E),
        ),
        body: const Center(
          child: Text(
            'Access Denied\nYou do not have permission to manage users',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const DinosaurLoadingScreen(message: 'Loading users...', showProgress: true)
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Statistics Card
                        if (_stats != null) _buildStatsCard(),
                        
                        const SizedBox(height: 20),
                        
                        // Orphaned Users Section
                        if (_orphanedUsers.isNotEmpty) ...[
                          const Text(
                            'Orphaned Users (Need Cleanup)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._orphanedUsers.map((user) => _buildOrphanedUserCard(user)),
                          const SizedBox(height: 20),
                        ],
                        
                        // Regular Users Section
                        const Text(
                          'All Users',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ..._users.map((user) => _buildUserCard(user)),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      color: const Color(0xFF2D2D2D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Statistics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total', '${_stats!['total_users']}', Colors.blue),
                _buildStatItem('Active', '${_stats!['active_users']}', Colors.green),
                _buildStatItem('Orphaned', '${_stats!['orphaned_users']}', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildOrphanedUserCard(Map<String, dynamic> user) {
    return Card(
      color: Colors.orange.withOpacity(0.1),
      child: ListTile(
        leading: const Icon(Icons.warning, color: Colors.orange),
        title: Text(
          user['email'] ?? 'Unknown',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          'Created: ${user['created_at'] ?? 'Unknown'}',
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _showDeleteConfirmation(user['email']),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Card(
      color: const Color(0xFF2D2D2D),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user['role']),
          child: Text(
            user['role']?.toString().substring(0, 1).toUpperCase() ?? 'U',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          user['full_name'] ?? 'Unknown',
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user['email'] ?? 'Unknown',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              'Role: ${user['role'] ?? 'Unknown'}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _showDeleteConfirmation(user['email']);
            } else if (value.startsWith('role_')) {
              final newRole = value.substring(5);
              _updateUserRole(user['id'], newRole);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'role_user',
              child: Text('Set as User'),
            ),
            const PopupMenuItem(
              value: 'role_admin',
              child: Text('Set as Admin'),
            ),
            const PopupMenuItem(
              value: 'role_developer',
              child: Text('Set as Developer'),
            ),
            const PopupMenuItem(
              value: 'role_worker',
              child: Text('Set as Worker'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete User', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'developer':
        return Colors.blue;
      case 'worker':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showDeleteConfirmation(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Delete User', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete user: $email?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUser(email);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
