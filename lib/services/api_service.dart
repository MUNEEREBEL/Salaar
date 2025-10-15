// lib/services/api_service.dart
import 'package:supabase/supabase.dart';
import '../main.dart';

class ApiService {
  static SupabaseClient get client => supabase;

  static Future<bool> submitIssue({
    required String title,
    required String description,
    required String category,
    required double latitude,
    required double longitude,
    required String address,
    List<String>? imageUrls,
  }) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('Please sign in to submit issues');
      }

      final issueData = {
        'title': title,
        'description': description,
        'category': category,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'user_id': user.id,
        'image_urls': imageUrls ?? [],
        'status': 'pending',
      };

      print('Submitting issue: $issueData');
      
      final response = await client
          .from('issues')
          .insert(issueData)
          .select()
          .single();

      print('Issue submitted successfully!');
      return true;
    } catch (e) {
      print('API Service Error: $e');
      rethrow;
    }
  }

  // Fix for fetching issues - remove the join that doesn't exist
  static Future<List<Map<String, dynamic>>> getIssues() async {
    try {
      final response = await client
          .from('issues')
          .select('*')
          .order('created_at', ascending: false);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      print('Error fetching issues: $e');
      return [];
    }
  }

  // Fix for fetching user's issues
  static Future<List<Map<String, dynamic>>> getMyIssues() async {
    try {
      final user = client.auth.currentUser;
      if (user == null) return [];

      final response = await client
          .from('issues')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      print('Error fetching my issues: $e');
      return [];
    }
  }

  // Test connection
  static Future<bool> testConnection() async {
    try {
      await client.from('issues').select('id').limit(1);
      return true;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}