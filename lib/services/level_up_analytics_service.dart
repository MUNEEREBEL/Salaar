// lib/services/level_up_analytics_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class LevelUpAnalyticsService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Calculate user level based on experience points
  static int calculateLevel(int expPoints) {
    if (expPoints >= 1000) return 5;
    if (expPoints >= 700) return 4;
    if (expPoints >= 300) return 3;
    if (expPoints >= 100) return 2;
    return 1;
  }

  /// Get level name based on experience points
  static String getLevelName(int expPoints) {
    if (expPoints >= 1000) return 'SALAAR';
    if (expPoints >= 700) return 'Shouryaanga';
    if (expPoints >= 300) return 'Mannarasi';
    if (expPoints >= 100) return 'Ghaniyaar';
    return 'The Beginning';
  }

  /// Calculate experience needed for next level
  static int getExpNeededForNextLevel(int currentExp) {
    final currentLevel = calculateLevel(currentExp);
    if (currentLevel >= 5) return 0; // Max level reached

    final levelThresholds = [0, 100, 300, 700, 1000];
    return levelThresholds[currentLevel] - currentExp;
  }

  /// Add experience points to user
  static Future<Map<String, dynamic>> addExperiencePoints({
    required String userId,
    required int points,
    required String reason,
  }) async {
    try {
      // Get current user data
      final response = await _supabase
          .from('profiles')
          .select('exp_points, level')
          .eq('id', userId)
          .single();

      final currentExp = response['exp_points'] as int;
      final newExp = currentExp + points;
      final oldLevel = calculateLevel(currentExp);
      final newLevel = calculateLevel(newExp);

      // Update experience points
      await _supabase
          .from('profiles')
          .update({
            'exp_points': newExp,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Check if user leveled up
      bool leveledUp = newLevel > oldLevel;
      String levelName = getLevelName(newExp);

      // Log the experience gain
      await _logExperienceGain(userId, points, reason, leveledUp, newLevel);

      return {
        'success': true,
        'new_exp': newExp,
        'points_added': points,
        'leveled_up': leveledUp,
        'old_level': oldLevel,
        'new_level': newLevel,
        'level_name': levelName,
        'exp_to_next': getExpNeededForNextLevel(newExp),
      };
    } catch (e) {
      print('Error adding experience points: $e');
      return {
        'success': false,
        'message': 'Failed to add experience: $e',
      };
    }
  }

  /// Log experience gain for analytics
  static Future<void> _logExperienceGain(
    String userId,
    int points,
    String reason,
    bool leveledUp,
    int newLevel,
  ) async {
    try {
      await _supabase.from('experience_logs').insert({
        'user_id': userId,
        'points': points,
        'reason': reason,
        'leveled_up': leveledUp,
        'new_level': newLevel,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error logging experience gain: $e');
    }
  }

  /// Get user analytics
  static Future<Map<String, dynamic>> getUserAnalytics(String userId) async {
    try {
      // Get user profile data
      final profile = await _supabase
          .from('profiles')
          .select('exp_points, issues_reported, issues_verified, created_at')
          .eq('id', userId)
          .single();

      final expPoints = profile['exp_points'] as int;
      final issuesReported = profile['issues_reported'] as int;
      final issuesVerified = profile['issues_verified'] as int;
      final createdAt = DateTime.parse(profile['created_at'] as String);

      // Get experience logs
      final expLogs = await _supabase
          .from('experience_logs')
          .select('points, reason, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(10);

      // Get recent activity
      final recentIssues = await _supabase
          .from('issues')
          .select('id, issue_type, status, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(5);

      // Calculate statistics
      final currentLevel = calculateLevel(expPoints);
      final levelName = getLevelName(expPoints);
      final expToNext = getExpNeededForNextLevel(expPoints);
      final daysActive = DateTime.now().difference(createdAt).inDays;

      return {
        'success': true,
        'user_id': userId,
        'current_level': currentLevel,
        'level_name': levelName,
        'exp_points': expPoints,
        'exp_to_next_level': expToNext,
        'issues_reported': issuesReported,
        'issues_verified': issuesVerified,
        'days_active': daysActive,
        'recent_experience': expLogs,
        'recent_issues': recentIssues,
        'level_progress': (expPoints / 1000 * 100).clamp(0, 100).toDouble(),
      };
    } catch (e) {
      print('Error getting user analytics: $e');
      return {
        'success': false,
        'message': 'Failed to get analytics: $e',
      };
    }
  }

  /// Get leaderboard data
  static Future<Map<String, dynamic>> getLeaderboard({
    String period = 'week', // week, month, all
    int limit = 10,
  }) async {
    try {
      String dateFilter = '';
      switch (period) {
        case 'week':
          dateFilter = "created_at >= NOW() - INTERVAL '7 days'";
          break;
        case 'month':
          dateFilter = "created_at >= NOW() - INTERVAL '30 days'";
          break;
        default:
          dateFilter = '1=1'; // All time
      }

      final response = await _supabase
          .from('profiles')
          .select('id, username, full_name, exp_points, issues_reported, issues_verified')
          .eq('is_active', true)
          .order('exp_points', ascending: false)
          .limit(limit);

      final leaderboard = response.map<Map<String, dynamic>>((user) {
        final expPoints = user['exp_points'] as int;
        return {
          'id': user['id'],
          'username': user['username'],
          'full_name': user['full_name'],
          'exp_points': expPoints,
          'level': calculateLevel(expPoints),
          'level_name': getLevelName(expPoints),
          'issues_reported': user['issues_reported'],
          'issues_verified': user['issues_verified'],
        };
      }).toList();

      return {
        'success': true,
        'period': period,
        'leaderboard': leaderboard,
        'total_users': leaderboard.length,
      };
    } catch (e) {
      print('Error getting leaderboard: $e');
      return {
        'success': false,
        'message': 'Failed to get leaderboard: $e',
      };
    }
  }

  /// Get system analytics (admin only)
  static Future<Map<String, dynamic>> getSystemAnalytics() async {
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
      if (role != 'admin' && role != 'developer') {
        return {'success': false, 'message': 'Insufficient permissions'};
      }

      // Get total users
      final totalUsersList = await _supabase
          .from('profiles')
          .select('id');
      final totalUsers = totalUsersList.length;

      // Get total issues
      final totalIssuesList = await _supabase
          .from('issues')
          .select('id');
      final totalIssues = totalIssuesList.length;

      // Get issues by status
      final issuesByStatus = await _supabase
          .from('issues')
          .select('status');

      final statusCounts = <String, int>{};
      for (final issue in issuesByStatus) {
        final status = issue['status'] as String;
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }

      // Get users by level
      final usersByLevel = await _supabase
          .from('profiles')
          .select('exp_points');

      final levelCounts = <String, int>{};
      for (final user in usersByLevel) {
        final expPoints = user['exp_points'] as int;
        final level = calculateLevel(expPoints);
        levelCounts['Level $level'] = (levelCounts['Level $level'] ?? 0) + 1;
      }

      // Get recent activity
      final recentActivity = await _supabase
          .from('issues')
          .select('created_at')
          .order('created_at', ascending: false)
          .limit(100);

      final now = DateTime.now();
      final last24Hours = recentActivity
          .where((activity) {
            final createdAt = DateTime.parse(activity['created_at'] as String);
            return now.difference(createdAt).inHours < 24;
          })
          .length;

      return {
        'success': true,
        'total_users': totalUsers,
        'total_issues': totalIssues,
        'issues_by_status': statusCounts,
        'users_by_level': levelCounts,
        'recent_activity_24h': last24Hours,
        'system_health': 'healthy',
      };
    } catch (e) {
      print('Error getting system analytics: $e');
      return {
        'success': false,
        'message': 'Failed to get system analytics: $e',
      };
    }
  }

  /// Award experience for specific actions
  static Future<Map<String, dynamic>> awardExperienceForAction({
    required String userId,
    required String action,
  }) async {
    int points = 0;
    String reason = '';

    switch (action) {
      case 'report_issue':
        points = 10;
        reason = 'Reported an issue';
        break;
      case 'verify_issue':
        points = 20;
        reason = 'Verified an issue';
        break;
      case 'complete_assignment':
        points = 30;
        reason = 'Completed assignment';
        break;
      case 'first_report':
        points = 50;
        reason = 'First issue report';
        break;
      case 'weekly_leaderboard_1':
        points = 100;
        reason = 'Weekly leaderboard #1';
        break;
      case 'weekly_leaderboard_2':
        points = 75;
        reason = 'Weekly leaderboard #2';
        break;
      case 'weekly_leaderboard_3':
        points = 50;
        reason = 'Weekly leaderboard #3';
        break;
      default:
        points = 5;
        reason = 'General activity';
    }

    return await addExperiencePoints(
      userId: userId,
      points: points,
      reason: reason,
    );
  }

  /// Refresh user level data
  static Future<void> refreshUserLevel(String? userId) async {
    if (userId == null) return;
    
    try {
      // Get current user data
      final response = await _supabase
          .from('profiles')
          .select('exp_points')
          .eq('id', userId)
          .single();

      final currentExp = response['exp_points'] as int;
      final currentLevel = calculateLevel(currentExp);
      final levelName = getLevelName(currentExp);

      // Update level in database
      await _supabase
          .from('profiles')
          .update({
            'level': currentLevel,
            'level_name': levelName,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      print('User level refreshed: Level $currentLevel ($levelName)');
    } catch (e) {
      print('Error refreshing user level: $e');
    }
  }
}
