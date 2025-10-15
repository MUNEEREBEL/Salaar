// lib/services/account_deletion_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class AccountDeletionService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Delete current user's account (self-deletion)
  static Future<Map<String, dynamic>> deleteCurrentUserAccount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      // Delete from profiles first
      await _supabase
          .from('profiles')
          .delete()
          .eq('id', user.id);

      // Delete from auth.users (this will also sign out the user)
      await _supabase.auth.admin.deleteUser(user.id);

      return {
        'success': true,
        'message': 'Account deleted successfully',
      };
    } catch (e) {
      print('Error deleting current user account: $e');
      return {
        'success': false,
        'message': 'Failed to delete account: $e',
      };
    }
  }

  /// Delete any user account (admin/developer only)
  static Future<Map<String, dynamic>> deleteUserAccount(String userId) async {
    try {
      // Check if current user has admin/developer permissions
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', currentUser.id)
          .single();

      final role = profile['role'] as String?;
      if (role != 'admin' && role != 'developer') {
        return {'success': false, 'message': 'Insufficient permissions'};
      }

      // Delete from profiles first
      await _supabase
          .from('profiles')
          .delete()
          .eq('id', userId);

      // Delete from auth.users
      await _supabase.auth.admin.deleteUser(userId);

      return {
        'success': true,
        'message': 'User account deleted successfully',
      };
    } catch (e) {
      print('Error deleting user account: $e');
      return {
        'success': false,
        'message': 'Failed to delete user account: $e',
      };
    }
  }

  /// Delete user by email (admin/developer only)
  static Future<Map<String, dynamic>> deleteUserByEmail(String email) async {
    try {
      // Check permissions
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', currentUser.id)
          .single();

      final role = profile['role'] as String?;
      if (role != 'admin' && role != 'developer') {
        return {'success': false, 'message': 'Insufficient permissions'};
      }

      // Find user by email
      final user = await _supabase
          .from('profiles')
          .select('id')
          .eq('email', email)
          .single();

      if (user == null) {
        return {'success': false, 'message': 'User not found'};
      }

      final userId = user['id'] as String;

      // Delete from profiles
      await _supabase
          .from('profiles')
          .delete()
          .eq('id', userId);

      // Delete from auth.users
      await _supabase.auth.admin.deleteUser(userId);

      return {
        'success': true,
        'message': 'User account deleted successfully',
      };
    } catch (e) {
      print('Error deleting user by email: $e');
      return {
        'success': false,
        'message': 'Failed to delete user: $e',
      };
    }
  }

  /// Bulk delete users (admin only)
  static Future<Map<String, dynamic>> bulkDeleteUsers(List<String> userIds) async {
    try {
      // Check if current user is admin
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', currentUser.id)
          .single();

      final role = profile['role'] as String?;
      if (role != 'admin') {
        return {'success': false, 'message': 'Admin permissions required'};
      }

      int deletedCount = 0;
      List<String> errors = [];

      for (String userId in userIds) {
        try {
          // Delete from profiles
          await _supabase
              .from('profiles')
              .delete()
              .eq('id', userId);

          // Delete from auth.users
          await _supabase.auth.admin.deleteUser(userId);
          deletedCount++;
        } catch (e) {
          errors.add('Failed to delete user $userId: $e');
        }
      }

      return {
        'success': true,
        'message': 'Bulk deletion completed',
        'deleted_count': deletedCount,
        'total_count': userIds.length,
        'errors': errors,
      };
    } catch (e) {
      print('Error in bulk delete: $e');
      return {
        'success': false,
        'message': 'Bulk deletion failed: $e',
      };
    }
  }

  /// Get deletion statistics
  static Future<Map<String, dynamic>> getDeletionStats() async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'message': 'No user logged in'};
      }

      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', currentUser.id)
          .single();

      final role = profile['role'] as String?;
      if (role != 'admin' && role != 'developer') {
        return {'success': false, 'message': 'Insufficient permissions'};
      }

      // Get total users
      final totalUsers = await _supabase
          .from('profiles')
          .select('id');

      // Get users by role
      final roleStats = await _supabase
          .from('profiles')
          .select('role')
          .eq('is_active', true);

      final roleCounts = <String, int>{};
      for (final user in roleStats) {
        final userRole = user['role'] as String;
        roleCounts[userRole] = (roleCounts[userRole] ?? 0) + 1;
      }

      return {
        'success': true,
        'total_users': totalUsers.length,
        'active_users': roleStats.length,
        'role_distribution': roleCounts,
        'can_delete': true,
      };
    } catch (e) {
      print('Error getting deletion stats: $e');
      return {
        'success': false,
        'message': 'Failed to get stats: $e',
      };
    }
  }
}
