// lib/providers/announcements_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Announcement {
  final String id;
  final String title;
  final String content;
  final String type;
  final String createdBy;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? authorName;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdBy,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.authorName,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      type: json['type'] ?? 'info',
      createdBy: json['created_by'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      authorName: json['profiles']?['full_name'],
    );
  }
}

class AnnouncementsProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Announcement> _announcements = [];
  bool _isLoading = false;
  String? _error;

  List<Announcement> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchActiveAnnouncements() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _supabase
          .from('announcements')
          .select('*, profiles(full_name)')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(10);

      _announcements = (response as List)
          .map((data) => Announcement.fromJson(data))
          .toList();
    } catch (e) {
      _error = e.toString();
      print('Error fetching announcements: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAnnouncement({
    required String title,
    required String content,
    required String type,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase.from('announcements').insert({
        'title': title,
        'content': content,
        'type': type,
        'created_by': user.id,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await fetchActiveAnnouncements();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}