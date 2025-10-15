// lib/providers/user_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppUser {
  final String id;
  final String role;
  final String? fullName;
  final double radius;
  final double? locationLat;
  final double? locationLong;
  final int expPoints;
  final int issuesReported;
  final int issuesVerified;
  final DateTime updatedAt;

  AppUser({
    required this.id,
    required this.role,
    this.fullName,
    required this.radius,
    this.locationLat,
    this.locationLong,
    required this.expPoints,
    required this.issuesReported,
    required this.issuesVerified,
    required this.updatedAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      role: json['role'] ?? 'user',
      fullName: json['full_name'],
      radius: (json['radius'] ?? 5000).toDouble(),
      locationLat: json['location_lat']?.toDouble(),
      locationLong: json['location_long']?.toDouble(),
      expPoints: json['exp_points'] ?? 0,
      issuesReported: json['issues_reported'] ?? 0,
      issuesVerified: json['issues_verified'] ?? 0,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Add getter for user (to fix the error)
  AppUser get user => this;

  int get level {
    if (expPoints < 100) return 1;
    if (expPoints < 300) return 2;
    if (expPoints < 600) return 3;
    if (expPoints < 1000) return 4;
    return 5;
  }
}

class UserProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  AppUser? _currentUser;
  bool _loading = false;

  AppUser? get currentUser => _currentUser;
  AppUser? get user => _currentUser; // Add this getter to fix the error
  bool get loading => _loading;
  bool get isLoggedIn => _currentUser != null;

  // Fix: Add setUser method
  Future<void> setUser(AppUser user, String role) async {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> loadCurrentUser() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return;

    _loading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', authUser.id)
          .single();

      _currentUser = AppUser.fromJson(response);
    } catch (e) {
      print('Error loading user: $e');
      await _createUserProfile(authUser.id, authUser.email ?? '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _createUserProfile(String userId, String email) async {
    try {
      await _supabase.from('profiles').insert({
        'id': userId,
        'full_name': email.split('@').first,
        'role': 'user',
      });

      await loadCurrentUser();
    } catch (e) {
      print('Error creating user profile: $e');
    }
  }

  // Fix: Add logout method
  Future<void> logout() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateUserLocation(double lat, double long) async {
    if (_currentUser == null) return;

    try {
      await _supabase.from('profiles').update({
        'location_lat': lat,
        'location_long': long,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', _currentUser!.id);

      await loadCurrentUser();
    } catch (e) {
      print('Error updating user location: $e');
    }
  }
}