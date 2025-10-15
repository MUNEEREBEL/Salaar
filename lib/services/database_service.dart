// lib/services/database_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ISSUES OPERATIONS
  static Future<List<Map<String, dynamic>>> getAllIssues() async {
    try {
      final response = await _supabase
          .from('issues')
          .select('*')
          .order('created_at', ascending: false);
      return response as List<Map<String, dynamic>>;
    } catch (e) {
      print('Error fetching issues: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getUserIssues(String userId) async {
    try {
      final response = await _supabase
          .from('issues')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return response as List<Map<String, dynamic>>;
    } catch (e) {
      print('Error fetching user issues: $e');
      return [];
    }
  }

  static Future<bool> createIssue(Map<String, dynamic> issueData) async {
    try {
      await _supabase.from('issues').insert(issueData);
      return true;
    } catch (e) {
      print('Error creating issue: $e');
      return false;
    }
  }

  static Future<bool> updateIssue(String issueId, Map<String, dynamic> updateData) async {
    try {
      await _supabase
          .from('issues')
          .update(updateData)
          .eq('id', issueId);
      return true;
    } catch (e) {
      print('Error updating issue: $e');
      return false;
    }
  }

  static Future<bool> deleteIssue(String issueId) async {
    try {
      // Delete related records first
      await _supabase.from('issue_history').delete().eq('issue_id', issueId);
      await _supabase.from('ai_analysis').delete().eq('issue_id', issueId);
      await _supabase.from('assignments').delete().eq('issue_id', issueId);
      await _supabase.from('discussions').delete().eq('issue_id', issueId);
      await _supabase.from('report_discussions').delete().eq('issue_id', issueId);
      
      // Delete main issue
      await _supabase.from('issues').delete().eq('id', issueId);
      return true;
    } catch (e) {
      print('Error deleting issue: $e');
      return false;
    }
  }

  // DISCUSSIONS OPERATIONS
  static Future<List<Map<String, dynamic>>> getAllDiscussions() async {
    try {
      final response = await _supabase
          .from('discussions')
          .select('*, profiles(full_name, username)')
          .order('created_at', ascending: false);
      return response as List<Map<String, dynamic>>;
    } catch (e) {
      print('Error fetching discussions: $e');
      return [];
    }
  }

  static Future<bool> createDiscussion(Map<String, dynamic> discussionData) async {
    try {
      await _supabase.from('discussions').insert(discussionData);
      return true;
    } catch (e) {
      print('Error creating discussion: $e');
      return false;
    }
  }

  // LEADERBOARD OPERATIONS
  static Future<List<Map<String, dynamic>>> getLeaderboard() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('full_name, username, exp_points, issues_reported, issues_verified')
          .order('exp_points', ascending: false)
          .limit(10);
      return response as List<Map<String, dynamic>>;
    } catch (e) {
      print('Error fetching leaderboard: $e');
      return [];
    }
  }

  // ANALYTICS OPERATIONS
  static Future<Map<String, dynamic>> getAnalytics() async {
    try {
      // Get total issues count
      final totalIssues = await _supabase
          .from('issues')
          .select('*')
          .then((response) => (response as List).length);

      // Get completed issues count
      final completedIssues = await _supabase
          .from('issues')
          .select('*')
          .eq('status', 'completed')
          .then((response) => (response as List).length);

      // Get verified issues count
      final verifiedIssues = await _supabase
          .from('issues')
          .select('*')
          .eq('status', 'verified')
          .then((response) => (response as List).length);

      return {
        'total_issues': totalIssues,
        'completed_issues': completedIssues,
        'verified_issues': verifiedIssues,
        'success_rate': totalIssues > 0 ? ((completedIssues / totalIssues) * 100).round() : 0,
      };
    } catch (e) {
      print('Error fetching analytics: $e');
      return {
        'total_issues': 0,
        'completed_issues': 0,
        'verified_issues': 0,
        'success_rate': 0,
      };
    }
  }

  // USER OPERATIONS
  static Future<bool> updateUserStats(String userId, {
    int? reportsDelta,
    int? verifiedDelta,
    int? xpDelta,
  }) async {
    try {
      await _supabase.rpc('increment_profile_counters', params: {
        'profile_id': userId,
        'reports_delta': reportsDelta ?? 0,
        'verified_delta': verifiedDelta ?? 0,
        'xp_delta': xpDelta ?? 0,
      });
      return true;
    } catch (e) {
      print('Error updating user stats: $e');
      return false;
    }
  }

  // ANNOUNCEMENTS OPERATIONS
  static Future<List<Map<String, dynamic>>> getAnnouncements() async {
    try {
      final response = await _supabase
          .from('announcements')
          .select('*, profiles(full_name)')
          .eq('is_active', true)
          .order('created_at', ascending: false);
      return response as List<Map<String, dynamic>>;
    } catch (e) {
      print('Error fetching announcements: $e');
      return [];
    }
  }
}
