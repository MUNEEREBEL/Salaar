// lib/providers/permissions_provider.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/permissions.dart';

class PermissionsProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  UserPermissions? _currentUserPermissions;
  Map<String, UserPermissions> _userPermissions = {};
  bool _isLoading = false;
  String? _error;

  UserPermissions? get currentUserPermissions => _currentUserPermissions;
  Map<String, UserPermissions> get userPermissions => _userPermissions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Check if current user has specific permission
  bool hasPermission(String permission) {
    if (_currentUserPermissions == null) return false;
    
    switch (permission) {
      case 'view_reports':
        return _currentUserPermissions!.canViewReports;
      case 'edit_reports':
        return _currentUserPermissions!.canEditReports;
      case 'delete_reports':
        return _currentUserPermissions!.canDeleteReports;
      case 'assign_tasks':
        return _currentUserPermissions!.canAssignTasks;
      case 'create_workers':
        return _currentUserPermissions!.canCreateWorkers;
      case 'manage_users':
        return _currentUserPermissions!.canManageUsers;
      case 'export_data':
        return _currentUserPermissions!.canExportData;
      case 'view_analytics':
        return _currentUserPermissions!.canViewAnalytics;
      case 'send_notifications':
        return _currentUserPermissions!.canSendNotifications;
      case 'moderate_community':
        return _currentUserPermissions!.canModerateCommunity;
      case 'access_developer_tools':
        return _currentUserPermissions!.canAccessDeveloperTools;
      default:
        return false;
    }
  }

  // Load current user permissions
  Future<void> loadCurrentUserPermissions() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _supabase
          .from('user_permissions')
          .select()
          .eq('user_id', user.id)
          .single();

      _currentUserPermissions = UserPermissions.fromJson(response);
    } catch (e) {
      // If no permissions found, create default based on user role
      await _createDefaultPermissions(user.id);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create default permissions based on user role
  Future<void> _createDefaultPermissions(String userId) async {
    try {
      // Get user role from profiles table
      final profileResponse = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();

      final role = profileResponse['role'] as String? ?? 'user';
      
      UserPermissions defaultPermissions;
      switch (role) {
        case 'admin':
          defaultPermissions = UserPermissions.getDefaultAdminPermissions(userId);
          break;
        case 'worker':
          defaultPermissions = UserPermissions.getDefaultWorkerPermissions(userId);
          break;
        case 'developer':
          defaultPermissions = UserPermissions.getDefaultDeveloperPermissions(userId);
          break;
        default:
          defaultPermissions = UserPermissions.getDefaultUserPermissions(userId);
      }

      await _supabase
          .from('user_permissions')
          .insert(defaultPermissions.toJson());

      _currentUserPermissions = defaultPermissions;
    } catch (e) {
      _error = 'Failed to create default permissions: $e';
      print('Error creating default permissions: $e');
    }
  }

  // Load permissions for a specific user
  Future<void> loadUserPermissions(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _supabase
          .from('user_permissions')
          .select()
          .eq('user_id', userId)
          .single();

      _userPermissions[userId] = UserPermissions.fromJson(response);
    } catch (e) {
      _error = 'Failed to load user permissions: $e';
      print('Error loading user permissions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update user permissions
  Future<bool> updateUserPermissions(String userId, UserPermissions permissions) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedPermissions = permissions.copyWith(updatedAt: DateTime.now());
      
      await _supabase
          .from('user_permissions')
          .update(updatedPermissions.toJson())
          .eq('user_id', userId);

      _userPermissions[userId] = updatedPermissions;
      
      // If updating current user, update current permissions too
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null && currentUser.id == userId) {
        _currentUserPermissions = updatedPermissions;
      }

      return true;
    } catch (e) {
      _error = 'Failed to update permissions: $e';
      print('Error updating permissions: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Bulk update permissions for multiple users
  Future<bool> bulkUpdatePermissions(Map<String, UserPermissions> permissionsMap) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      for (final entry in permissionsMap.entries) {
        final updatedPermissions = entry.value.copyWith(updatedAt: DateTime.now());
        
        await _supabase
            .from('user_permissions')
            .update(updatedPermissions.toJson())
            .eq('user_id', entry.key);

        _userPermissions[entry.key] = updatedPermissions;
      }

      return true;
    } catch (e) {
      _error = 'Failed to bulk update permissions: $e';
      print('Error bulk updating permissions: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reset permissions to default for a user
  Future<bool> resetToDefaultPermissions(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get user role
      final profileResponse = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();

      final role = profileResponse['role'] as String? ?? 'user';
      
      UserPermissions defaultPermissions;
      switch (role) {
        case 'admin':
          defaultPermissions = UserPermissions.getDefaultAdminPermissions(userId);
          break;
        case 'worker':
          defaultPermissions = UserPermissions.getDefaultWorkerPermissions(userId);
          break;
        case 'developer':
          defaultPermissions = UserPermissions.getDefaultDeveloperPermissions(userId);
          break;
        default:
          defaultPermissions = UserPermissions.getDefaultUserPermissions(userId);
      }

      await _supabase
          .from('user_permissions')
          .update(defaultPermissions.toJson())
          .eq('user_id', userId);

      _userPermissions[userId] = defaultPermissions;
      
      // If resetting current user, update current permissions too
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null && currentUser.id == userId) {
        _currentUserPermissions = defaultPermissions;
      }

      return true;
    } catch (e) {
      _error = 'Failed to reset permissions: $e';
      print('Error resetting permissions: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get permission display name
  String getPermissionDisplayName(String permission) {
    switch (permission) {
      case 'view_reports':
        return 'View Reports';
      case 'edit_reports':
        return 'Edit Reports';
      case 'delete_reports':
        return 'Delete Reports';
      case 'assign_tasks':
        return 'Assign Tasks';
      case 'create_workers':
        return 'Create Workers';
      case 'manage_users':
        return 'Manage Users';
      case 'export_data':
        return 'Export Data';
      case 'view_analytics':
        return 'View Analytics';
      case 'send_notifications':
        return 'Send Notifications';
      case 'moderate_community':
        return 'Moderate Community';
      case 'access_developer_tools':
        return 'Access Developer Tools';
      default:
        return permission;
    }
  }

  // Get permission description
  String getPermissionDescription(String permission) {
    switch (permission) {
      case 'view_reports':
        return 'Can view all reports and issue details';
      case 'edit_reports':
        return 'Can edit report details and status';
      case 'delete_reports':
        return 'Can delete reports permanently';
      case 'assign_tasks':
        return 'Can assign tasks to workers';
      case 'create_workers':
        return 'Can create new worker accounts';
      case 'manage_users':
        return 'Can manage user accounts and roles';
      case 'export_data':
        return 'Can export data to CSV/PDF';
      case 'view_analytics':
        return 'Can view analytics and reports';
      case 'send_notifications':
        return 'Can send notifications to users';
      case 'moderate_community':
        return 'Can moderate community discussions';
      case 'access_developer_tools':
        return 'Can access developer debugging tools';
      default:
        return 'Unknown permission';
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
