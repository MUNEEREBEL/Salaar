// lib/services/gamification_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class GamificationService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Level definitions as per requirements
  static const Map<int, Map<String, dynamic>> LEVELS = {
    1: {'name': 'The Beginning', 'xpRequired': 100, 'description': 'Welcome to SALAAR'},
    2: {'name': 'Ghaniyaar', 'xpRequired': 300, 'description': 'Rising through the ranks'},
    3: {'name': 'Mannarasi', 'xpRequired': 700, 'description': 'Proven contributor'},
    4: {'name': 'Shouryaanga', 'xpRequired': 1000, 'description': 'Elite warrior'},
    5: {'name': 'SALAAR', 'xpRequired': 9999, 'description': 'Ultimate champion'},
  };

  // XP Rewards
  static const int VERIFIED_REPORT_XP = 20;
  static const int WEEKLY_LEADERBOARD_RANK_1_XP = 100;
  static const int WEEKLY_LEADERBOARD_RANK_2_XP = 50;
  static const int WEEKLY_LEADERBOARD_RANK_3_XP = 30;

  /// Award XP for verified report
  static Future<bool> awardVerifiedReportXP(String userId) async {
    try {
      final response = await _supabase.rpc('increment_profile_counters', params: {
        'user_id': userId,
        'xp_increment': VERIFIED_REPORT_XP,
        'issues_verified_increment': 1,
      });
      return response == true;
    } catch (e) {
      print('Error awarding verified report XP: $e');
      return false;
    }
  }

  /// Award XP for weekly leaderboard position
  static Future<bool> awardLeaderboardXP(String userId, int rank) async {
    try {
      int xpReward = 0;
      switch (rank) {
        case 1:
          xpReward = WEEKLY_LEADERBOARD_RANK_1_XP;
          break;
        case 2:
          xpReward = WEEKLY_LEADERBOARD_RANK_2_XP;
          break;
        case 3:
          xpReward = WEEKLY_LEADERBOARD_RANK_3_XP;
          break;
        default:
          return false;
      }

      final response = await _supabase.rpc('increment_profile_counters', params: {
        'user_id': userId,
        'xp_increment': xpReward,
      });
      return response == true;
    } catch (e) {
      print('Error awarding leaderboard XP: $e');
      return false;
    }
  }

  /// Get level information for given XP
  static Map<String, dynamic> getLevelInfo(int xp) {
    for (int level = 5; level >= 1; level--) {
      if (xp >= LEVELS[level]!['xpRequired']) {
        return {
          'level': level,
          'name': LEVELS[level]!['name'],
          'description': LEVELS[level]!['description'],
          'xpRequired': LEVELS[level]!['xpRequired'],
          'xpCurrent': xp,
          'xpToNext': level < 5 ? LEVELS[level + 1]!['xpRequired'] - xp : 0,
          'progress': level < 5 ? (xp - LEVELS[level]!['xpRequired']) / 
                     (LEVELS[level + 1]!['xpRequired'] - LEVELS[level]!['xpRequired']) : 1.0,
        };
      }
    }
    return {
      'level': 1,
      'name': 'The Beginning',
      'description': 'Welcome to SALAAR',
      'xpRequired': 0,
      'xpCurrent': xp,
      'xpToNext': 100 - xp,
      'progress': xp / 100,
    };
  }

  /// Get weekly leaderboard
  static Future<List<Map<String, dynamic>>> getWeeklyLeaderboard() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, full_name, username, exp_points, issues_verified')
          .gte('issues_verified', 2) // Minimum 2 verified reports for leaderboard
          .order('exp_points', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching leaderboard: $e');
      return [];
    }
  }

  /// Get user's leaderboard position
  static Future<int> getUserLeaderboardPosition(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('exp_points')
          .eq('id', userId)
          .single();

      final userXp = response['exp_points'] as int;

      final higherXpUsers = await _supabase
          .from('profiles')
          .select('id')
          .gte('issues_verified', 2)
          .gt('exp_points', userXp);

      return higherXpUsers.length + 1;
    } catch (e) {
      print('Error getting user position: $e');
      return 0;
    }
  }

  /// Check if user leveled up
  static bool checkLevelUp(int oldXp, int newXp) {
    final oldLevel = getLevelInfo(oldXp)['level'] as int;
    final newLevel = getLevelInfo(newXp)['level'] as int;
    return newLevel > oldLevel;
  }

  /// Get level badge color
  static String getLevelBadgeColor(int level) {
    switch (level) {
      case 1:
        return '#9E9E9E'; // Grey
      case 2:
        return '#4CAF50'; // Green
      case 3:
        return '#2196F3'; // Blue
      case 4:
        return '#FF9800'; // Orange
      case 5:
        return '#F44336'; // Red
      default:
        return '#9E9E9E';
    }
  }

  /// Get level icon
  static String getLevelIcon(int level) {
    switch (level) {
      case 1:
        return '🌱';
      case 2:
        return '🌿';
      case 3:
        return '🌳';
      case 4:
        return '🔥';
      case 5:
        return '👑';
      default:
        return '🌱';
    }
  }
}
