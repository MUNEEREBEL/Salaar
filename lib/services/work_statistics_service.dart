// lib/services/work_statistics_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkStatistics {
  final int totalReports;
  final int completedReports;
  final int verifiedReports;
  final int pendingReports;
  final int xpPoints;
  final int level;

  WorkStatistics({
    required this.totalReports,
    required this.completedReports,
    required this.verifiedReports,
    required this.pendingReports,
    required this.xpPoints,
    required this.level,
  });

  factory WorkStatistics.empty() {
    return WorkStatistics(
      totalReports: 0,
      completedReports: 0,
      verifiedReports: 0,
      pendingReports: 0,
      xpPoints: 0,
      level: 1,
    );
  }
}

class WorkStatisticsService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Calculate real work statistics from database
  static Future<WorkStatistics> calculateWorkStatistics(String userId) async {
    try {
      // Get all issues reported by this user
      final issuesResponse = await _supabase
          .from('issues')
          .select('status')
          .eq('user_id', userId);

      final issues = issuesResponse as List;
      
      // Count reports by status
      int totalReports = issues.length;
      int completedReports = issues.where((issue) => issue['status'] == 'completed').length;
      int verifiedReports = issues.where((issue) => issue['status'] == 'verified').length;
      int pendingReports = issues.where((issue) => issue['status'] == 'pending').length;

      // Calculate XP based on actual data
      // +10 XP for each report submitted
      // +10 XP for each verified report
      // +20 XP for each completed report
      int xpPoints = (totalReports * 10) + (verifiedReports * 10) + (completedReports * 20);

      // Calculate level based on XP
      int level = _calculateLevel(xpPoints);

      return WorkStatistics(
        totalReports: totalReports,
        completedReports: completedReports,
        verifiedReports: verifiedReports,
        pendingReports: pendingReports,
        xpPoints: xpPoints,
        level: level,
      );
    } catch (e) {
      print('Error calculating work statistics: $e');
      return WorkStatistics.empty();
    }
  }

  /// Calculate level based on XP points
  static int _calculateLevel(int xp) {
    if (xp < 100) return 1;
    if (xp < 300) return 2;
    if (xp < 700) return 3;
    if (xp < 1000) return 4;
    return 5; // Max level - SALAAR
  }

  /// Get level name based on level number
  static String getLevelName(int level) {
    switch (level) {
      case 1:
        return 'The Beginning';
      case 2:
        return 'Ghaniyaar';
      case 3:
        return 'Mannarasi';
      case 4:
        return 'Shouryaanga';
      case 5:
        return 'SALAAR';
      default:
        return 'The Beginning';
    }
  }

  /// Get XP needed for next level
  static int getXPForNextLevel(int currentLevel) {
    switch (currentLevel) {
      case 1:
        return 100;
      case 2:
        return 300;
      case 3:
        return 700;
      case 4:
        return 1000;
      case 5:
        return 0; // Max level reached
      default:
        return 0;
    }
  }

  /// Get XP progress for current level
  static int getXPProgress(int currentXP, int currentLevel) {
    int currentLevelXP = currentLevel == 1 ? 0 : getXPForNextLevel(currentLevel - 1);
    int nextLevelXP = getXPForNextLevel(currentLevel);
    return currentXP - currentLevelXP;
  }

  /// Get XP needed for next level
  static int getXPNeededForNextLevel(int currentXP, int currentLevel) {
    int currentLevelXP = currentLevel == 1 ? 0 : getXPForNextLevel(currentLevel - 1);
    int nextLevelXP = getXPForNextLevel(currentLevel);
    return nextLevelXP - currentLevelXP;
  }
}
