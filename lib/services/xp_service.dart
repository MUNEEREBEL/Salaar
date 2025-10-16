// lib/services/xp_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class XPService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Add XP to user and log it properly
  static Future<bool> addXP({
    required String userId,
    required int xpAmount,
    required String reason,
  }) async {
    try {
      print('🎯 Adding $xpAmount XP to user $userId for: $reason');

      // Use the database function to add XP and log it
      final response = await _supabase.rpc('add_xp_and_log', params: {
        'p_user_id': userId,
        'p_xp_amount': xpAmount,
        'p_reason': reason,
      });

      if (response == true) {
        print('✅ XP added successfully: +$xpAmount XP for $reason');
        return true;
      } else {
        print('❌ Failed to add XP via database function');
        return false;
      }
    } catch (e) {
      print('❌ Error adding XP: $e');
      
      // Fallback: Manual XP addition
      try {
        // Get current XP
        final profileResponse = await _supabase
            .from('profiles')
            .select('exp_points')
            .eq('id', userId)
            .single();

        final currentXP = profileResponse['exp_points'] as int;
        final newXP = currentXP + xpAmount;

        // Update XP in profiles table
        await _supabase
            .from('profiles')
            .update({
              'exp_points': newXP,
              'level': _calculateLevel(newXP),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId);

        // Log XP change
        await _supabase.from('xp_logs').insert({
          'user_id': userId,
          'xp_amount': xpAmount,
          'reason': reason,
          'created_at': DateTime.now().toIso8601String(),
        });

        print('✅ XP added via fallback method: +$xpAmount XP for $reason');
        return true;
      } catch (fallbackError) {
        print('❌ Fallback XP addition also failed: $fallbackError');
        return false;
      }
    }
  }

  /// Calculate level based on XP
  static int _calculateLevel(int xp) {
    if (xp >= 1000) return 5;
    if (xp >= 700) return 4;
    if (xp >= 300) return 3;
    if (xp >= 100) return 2;
    return 1;
  }

  /// Get user's XP history
  static Future<List<Map<String, dynamic>>> getXPHistory(String userId) async {
    try {
      final response = await _supabase
          .from('xp_logs')
          .select('xp_amount, reason, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(20);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching XP history: $e');
      return [];
    }
  }

  /// Get current user XP and level
  static Future<Map<String, dynamic>?> getCurrentXP(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('exp_points, level')
          .eq('id', userId)
          .single();

      return {
        'xp': response['exp_points'] as int,
        'level': response['level'] as int,
      };
    } catch (e) {
      print('Error fetching current XP: $e');
      return null;
    }
  }

  /// Award XP for specific actions
  static Future<bool> awardXPForAction({
    required String userId,
    required String action,
  }) async {
    int xpAmount = 0;
    String reason = '';

    switch (action) {
      case 'report_submitted':
        xpAmount = 10;
        reason = 'Reported an issue';
        break;
      case 'report_verified':
        xpAmount = 20;
        reason = 'Issue verified by admin';
        break;
      case 'report_completed':
        xpAmount = 30;
        reason = 'Issue completed by worker';
        break;
      case 'first_report':
        xpAmount = 50;
        reason = 'First issue report bonus';
        break;
      case 'weekly_leaderboard_1':
        xpAmount = 100;
        reason = 'Weekly leaderboard #1';
        break;
      case 'weekly_leaderboard_2':
        xpAmount = 75;
        reason = 'Weekly leaderboard #2';
        break;
      case 'weekly_leaderboard_3':
        xpAmount = 50;
        reason = 'Weekly leaderboard #3';
        break;
      default:
        xpAmount = 5;
        reason = 'General activity';
    }

    return await addXP(
      userId: userId,
      xpAmount: xpAmount,
      reason: reason,
    );
  }
}
