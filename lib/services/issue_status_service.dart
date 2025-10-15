// lib/services/issue_status_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class IssueStatusService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Update issue status with proper validation
  static Future<bool> updateIssueStatus({
    required String issueId,
    required String newStatus,
    String? comment,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate status
      const validStatuses = ['pending', 'in_progress', 'completed', 'cancelled', 'verified'];
      if (!validStatuses.contains(newStatus)) {
        throw Exception('Invalid status: $newStatus');
      }

      // Call the database function
      final response = await _supabase.rpc('update_issue_status', params: {
        'issue_id': issueId,
        'new_status': newStatus,
        'comment': comment,
      });

      return response == true;
    } catch (e) {
      print('Error updating issue status: $e');
      return false;
    }
  }

  // Assign issue to worker
  static Future<bool> assignIssueToWorker({
    required String issueId,
    required String workerId,
    String? notes,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create assignment record
      final assignmentData = {
        'issue_id': issueId,
        'worker_id': workerId,
        'assigned_by': user.id,
        'status': 'assigned',
        'notes': notes,
      };

      await _supabase.from('assignments').insert(assignmentData);

      // Update issue with assignee
      await _supabase
          .from('issues')
          .update({
            'assignee_id': workerId,
            'assigned_at': DateTime.now().toIso8601String(),
            'status': 'in_progress',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', issueId);

      return true;
    } catch (e) {
      print('Error assigning issue: $e');
      return false;
    }
  }

  // Get issue history
  static Future<List<Map<String, dynamic>>> getIssueHistory(String issueId) async {
    try {
      final response = await _supabase
          .from('issue_history')
          .select('''
            *,
            profiles!issue_history_user_id_fkey(full_name, username)
          ''')
          .eq('issue_id', issueId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => data as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching issue history: $e');
      return [];
    }
  }

  // Get worker assignments
  static Future<List<Map<String, dynamic>>> getWorkerAssignments(String workerId) async {
    try {
      final response = await _supabase
          .from('assignments')
          .select('''
            *,
            issues!inner(*),
            profiles!assignments_assigned_by_fkey(full_name, username)
          ''')
          .eq('worker_id', workerId)
          .order('assigned_at', ascending: false);

      return (response as List)
          .map((data) => data as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching worker assignments: $e');
      return [];
    }
  }

  // Get pending assignments (for admin)
  static Future<List<Map<String, dynamic>>> getPendingAssignments() async {
    try {
      final response = await _supabase
          .from('issues')
          .select('''
            *,
            profiles!issues_user_id_fkey(full_name, username)
          ''')
          .isFilter('assignee_id', null)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => data as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching pending assignments: $e');
      return [];
    }
  }

  // Update user role (admin only)
  static Future<bool> updateUserRole({
    required String userId,
    required String newRole,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Call the database function
      final response = await _supabase.rpc('update_user_role', params: {
        'target_user_id': userId,
        'new_role': newRole,
      });

      return response == true;
    } catch (e) {
      print('Error updating user role: $e');
      return false;
    }
  }

  // Get all users (admin only)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('*')
          .order('created_at', ascending: false);

      return (response as List)
          .map((data) => data as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  // Get issue statistics
  static Future<Map<String, dynamic>> getIssueStatistics() async {
    try {
      final response = await _supabase
          .from('issues')
          .select('status, priority, created_at');

      final issues = (response as List)
          .map((data) => data as Map<String, dynamic>)
          .toList();

      // Calculate statistics
      final totalIssues = issues.length;
      final statusCounts = <String, int>{};
      final priorityCounts = <String, int>{};
      final monthlyCounts = <String, int>{};

      for (final issue in issues) {
        // Status counts
        final status = issue['status'] as String;
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;

        // Priority counts
        final priority = issue['priority'] as String;
        priorityCounts[priority] = (priorityCounts[priority] ?? 0) + 1;

        // Monthly counts
        final createdAt = DateTime.parse(issue['created_at'] as String);
        final monthKey = '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';
        monthlyCounts[monthKey] = (monthlyCounts[monthKey] ?? 0) + 1;
      }

      return {
        'total_issues': totalIssues,
        'status_counts': statusCounts,
        'priority_counts': priorityCounts,
        'monthly_counts': monthlyCounts,
        'completion_rate': totalIssues > 0 
            ? ((statusCounts['completed'] ?? 0) / totalIssues * 100).round()
            : 0,
      };
    } catch (e) {
      print('Error fetching issue statistics: $e');
      return {
        'total_issues': 0,
        'status_counts': {},
        'priority_counts': {},
        'monthly_counts': {},
        'completion_rate': 0,
      };
    }
  }
}
