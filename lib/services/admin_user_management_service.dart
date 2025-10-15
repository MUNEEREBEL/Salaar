// lib/services/admin_user_management_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class AdminUserManagementService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Check if current user has admin or developer permissions
  static Future<bool> hasUserManagementPermissions() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      final role = response['role'] as String?;
      return role == 'admin' || role == 'developer';
    } catch (e) {
      print('Error checking permissions: $e');
      return false;
    }
  }

  /// List all orphaned users (users in auth.users but not in profiles)
  static Future<List<Map<String, dynamic>>> listOrphanedUsers() async {
    try {
      if (!await hasUserManagementPermissions()) {
        throw Exception('Insufficient permissions');
      }

      final response = await _supabase.rpc('list_orphaned_users_simple');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error listing orphaned users: $e');
      rethrow;
    }
  }

  /// Delete a user safely (admin/developer only)
  static Future<Map<String, dynamic>> deleteUserSafely(String email) async {
    try {
      if (!await hasUserManagementPermissions()) {
        throw Exception('Insufficient permissions');
      }

      final response = await _supabase.rpc('delete_orphaned_user_simple', params: {
        'user_email': email,
      });

      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  /// List all users with their roles
  static Future<List<Map<String, dynamic>>> listAllUsers() async {
    try {
      if (!await hasUserManagementPermissions()) {
        throw Exception('Insufficient permissions');
      }

      final response = await _supabase
          .from('profiles')
          .select('''
            id,
            email,
            role,
            full_name,
            username,
            created_at,
            is_active
          ''')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error listing users: $e');
      rethrow;
    }
  }

  /// Create a new user account (admin/developer only)
  static Future<Map<String, dynamic>> createUserAccount({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required String role,
  }) async {
    try {
      if (!await hasUserManagementPermissions()) {
        throw Exception('Insufficient permissions');
      }

      // Validate role
      if (!['user', 'admin', 'developer', 'worker'].contains(role)) {
        throw Exception('Invalid role: $role');
      }

      // Create user via Supabase Auth
      final authResponse = await _supabase.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          userMetadata: {
            'full_name': fullName,
            'username': username,
          },
          emailConfirm: true,
        ),
      );

      if (authResponse.user == null) {
        throw Exception('Failed to create user');
      }

      // Create profile with specified role
      final profileResponse = await _supabase
          .from('profiles')
          .insert({
            'id': authResponse.user!.id,
            'email': email,
            'full_name': fullName,
            'username': username,
            'role': role,
            'exp_points': 0,
            'issues_reported': 0,
            'issues_verified': 0,
            'is_active': true,
          })
          .select()
          .single();

      return {
        'success': true,
        'message': 'User created successfully',
        'user_id': authResponse.user!.id,
        'profile': profileResponse,
      };
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  /// Update user role (admin/developer only)
  static Future<Map<String, dynamic>> updateUserRole({
    required String userId,
    required String newRole,
  }) async {
    try {
      if (!await hasUserManagementPermissions()) {
        throw Exception('Insufficient permissions');
      }

      // Validate role
      if (!['user', 'admin', 'developer', 'worker'].contains(newRole)) {
        throw Exception('Invalid role: $newRole');
      }

      final response = await _supabase
          .from('profiles')
          .update({
            'role': newRole,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();

      return {
        'success': true,
        'message': 'User role updated successfully',
        'profile': response,
      };
    } catch (e) {
      print('Error updating user role: $e');
      rethrow;
    }
  }

  /// Deactivate user account (admin/developer only)
  static Future<Map<String, dynamic>> deactivateUser(String userId) async {
    try {
      if (!await hasUserManagementPermissions()) {
        throw Exception('Insufficient permissions');
      }

      final response = await _supabase
          .from('profiles')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();

      return {
        'success': true,
        'message': 'User deactivated successfully',
        'profile': response,
      };
    } catch (e) {
      print('Error deactivating user: $e');
      rethrow;
    }
  }

  /// Get user management statistics
  static Future<Map<String, dynamic>> getUserStats() async {
    try {
      if (!await hasUserManagementPermissions()) {
        throw Exception('Insufficient permissions');
      }

      // Get total users
      final totalUsersList = await _supabase
          .from('profiles')
          .select('id');
      final totalUsers = totalUsersList.length;

      // Get users by role
      final roleStats = await _supabase
          .from('profiles')
          .select('role')
          .eq('is_active', true);

      final roleCounts = <String, int>{};
      for (final user in roleStats) {
        final role = user['role'] as String;
        roleCounts[role] = (roleCounts[role] ?? 0) + 1;
      }

      // Get orphaned users count
      final orphanedUsers = await listOrphanedUsers();

      return {
        'total_users': totalUsers,
        'active_users': roleStats.length,
        'orphaned_users': orphanedUsers.length,
        'role_distribution': roleCounts,
      };
    } catch (e) {
      print('Error getting user stats: $e');
      rethrow;
    }
  }
}
