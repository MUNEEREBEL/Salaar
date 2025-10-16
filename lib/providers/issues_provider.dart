// lib/providers/issues_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/image_upload_service.dart';
import '../services/notification_service.dart';
import '../services/basic_notification_service.dart';
import '../services/prabhas_notification_service.dart';
import '../services/xp_service.dart';
import '../widgets/level_up_popup.dart';

class Issue {
  final String id;
  final String userId;
  final String issueType;
  final String description;
  final String status;
  final double latitude;
  final double longitude;
  final String? address;
  final String? imageUrl;
  final List<String> imageUrls;
  final String? priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? assigneeId;
  final String? reportId;
  final String? reporterName;
  final String? reporterEmail;
  final String? completionImageUrl;

  Issue({
    required this.id,
    required this.userId,
    required this.issueType,
    required this.description,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.address,
    this.imageUrl,
    this.imageUrls = const [],
    this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.assigneeId,
    this.reportId,
    this.reporterName,
    this.reporterEmail,
    this.completionImageUrl,
  });

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      issueType: json['issue_type'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      latitude: (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : 0.0,
      longitude: (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : 0.0,
      address: json['address'],
      imageUrl: json['image_url'],
      reportId: json['report_id'],
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      priority: json['priority'] ?? 'medium',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      assigneeId: json['assignee_id'],
      reporterName: json['reporter_name'],
      reporterEmail: json['reporter_email'],
      completionImageUrl: json['completion_image_url'],
    );
  }

  String get title => issueType;
  String get category => issueType;
  String get severity => priority ?? 'medium';
}

class IssuesProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Issue> _issues = [];
  List<Issue> _myIssues = [];
  List<Issue> _assignedIssues = [];
  bool _isLoading = false;
  String? _error;
  RealtimeChannel? _issuesChannel;

  List<Issue> get issues => _issues;
  List<Issue> get myIssues => _myIssues;
  List<Issue> get assignedIssues => _assignedIssues;
  bool get isLoading => _isLoading;
  String? get error => _error;

  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 1);

  void initializeRealtimeUpdates() {
    _issuesChannel = _supabase.channel('issues-realtime')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'issues',
        callback: (payload) {
          _handleRealtimeUpdate(payload);
        },
      )
      ..subscribe();
  }

  void _handleRealtimeUpdate(PostgresChangePayload payload) {
    try {
      final evt = payload.eventType;
      final newData = (payload.newRecord ?? {}) as Map<String, dynamic>;
      final oldData = (payload.oldRecord ?? {}) as Map<String, dynamic>;

      switch (evt) {
        case PostgresChangeEvent.insert:
          _addIssue(newData);
          break;
        case PostgresChangeEvent.update:
          _updateIssue(newData);
          break;
        case PostgresChangeEvent.delete:
          _removeIssue(oldData['id']);
          break;
        default:
          break;
      }
    } catch (e) {
      print('Error handling realtime update: $e');
    }
  }

  void _addIssue(Map<String, dynamic> data) {
    try {
      final issue = Issue.fromJson(data);
      _issues.insert(0, issue);
      notifyListeners();
    } catch (e) {
      print('Error adding issue: $e');
    }
  }

  void _updateIssue(Map<String, dynamic> data) {
    try {
      final issue = Issue.fromJson(data);
      final index = _issues.indexWhere((i) => i.id == issue.id);
      if (index != -1) {
        _issues[index] = issue;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating issue: $e');
    }
  }

  void _removeIssue(String? issueId) {
    if (issueId != null) {
      _issues.removeWhere((issue) => issue.id == issueId);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _issuesChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> fetchAllIssues({bool forceRefresh = false}) async {
    if (!forceRefresh && 
        _lastFetchTime != null && 
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration &&
        _issues.isNotEmpty) {
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      // Don't call notifyListeners() here to avoid setState during build

      final response = await _supabase
          .from('issues')
          .select()
          .order('created_at', ascending: false);

      _issues = (response as List)
          .map((data) => Issue.fromJson(data as Map<String, dynamic>))
          .toList();

      _lastFetchTime = DateTime.now();
    } catch (e) {
      _error = 'Failed to load issues: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMyIssues() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _myIssues = [];
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final response = await _supabase
          .from('issues')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      _myIssues = (response as List)
          .map((data) => Issue.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = 'Failed to load your issues: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // RBAC: Fetch issues assigned to the current worker only
  Future<void> fetchAssignedIssuesForWorker() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _assignedIssues = [];
      notifyListeners();
      return;
    }
    try {
      _isLoading = true;
      notifyListeners();
      final response = await _supabase
          .from('issues')
          .select()
          .eq('assignee_id', user.id)
          .order('created_at', ascending: false);
      _assignedIssues = (response as List)
          .map((data) => Issue.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = 'Failed to load assigned issues: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitIssue({
    required String title,
    required String description,
    required double latitude,
    required double longitude,
    String? address,
    required List<File> images,
    String? category,
    String? priority,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _error = 'Please login to submit issues';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Upload images first
      List<String> uploadedImageUrls = [];
      if (images.isNotEmpty) {
        uploadedImageUrls = await ImageUploadService.uploadImages(images);
      }

      final issueData = {
        'user_id': user.id,
        'title': title,
        'issue_type': category ?? 'other',
        'category': category ?? 'other', // Add the category field
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'address': address ?? 'Location not specified',
        'image_urls': uploadedImageUrls,
        'status': 'pending',
        'priority': priority ?? 'medium',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final result = await _supabase.from('issues').insert(issueData).select().single();
      final issueId = result['id'] as String;

      // Add XP for report submission using proper XP service
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        await XPService.awardXPForAction(
          userId: currentUser.id,
          action: 'report_submitted',
        );
      }

      print('✅ Report submitted successfully - XP added via XPService');

      _refreshDataInBackground();
      return true;
    } catch (e) {
      _error = 'Failed to submit issue: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateIssueStatus({
    required String issueId,
    required String newStatus,
    String? completionPhotoUrl,
    BuildContext? context,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      Map<String, dynamic>? issueRow;
      if (completionPhotoUrl != null) {
        final res = await _supabase
            .from('issues')
            .select('image_urls')
            .eq('id', issueId)
            .single();
        issueRow = res as Map<String, dynamic>;
      }
      final currentImages = List<String>.from((issueRow?['image_urls']) ?? []);
      if (completionPhotoUrl != null) currentImages.add(completionPhotoUrl);
      final update = <String, dynamic>{
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
        if (completionPhotoUrl != null) 'image_urls': currentImages,
      };

      await _supabase.from('issues').update(update).eq('id', issueId);

      if (newStatus == 'done') {
        final user = _supabase.auth.currentUser;
        if (user != null) {
          // XP tracking removed - will be calculated from actual data
          print('✅ Work completed - XP will be calculated from database');
          // Check for level up
          if (context != null) {
            await checkLevelUp(context, 20);
          }
        }
      } else if (newStatus == 'verified') {
        final user = _supabase.auth.currentUser;
        if (user != null) {
          // XP tracking removed - will be calculated from actual data
          print('✅ Issue verified - XP will be calculated from database');
          // Check for level up
          if (context != null) {
            await checkLevelUp(context, 10);
          }
        }
      }

      _refreshDataInBackground();
      return true;
    } catch (e) {
      _error = 'Failed to update issue: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _refreshDataInBackground() {
    Future.delayed(const Duration(milliseconds: 500), () {
      fetchAllIssues(forceRefresh: true);
      fetchMyIssues();
      fetchAssignedIssuesForWorker();
      notifyListeners();
    });
  }

  // Force refresh all data
  Future<void> forceRefreshAll() async {
    _lastFetchTime = null;
    await fetchAllIssues(forceRefresh: true);
    await fetchMyIssues();
    await fetchAssignedIssuesForWorker();
    notifyListeners();
  }

  void clearCache() {
    _lastFetchTime = null;
  }

  // Check for level up and show popup
  Future<void> checkLevelUp(BuildContext context, int newXP) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Get current user profile
      final profileResponse = await _supabase
          .from('profiles')
          .select('exp_points, level')
          .eq('id', user.id)
          .single();

      final currentXP = profileResponse['exp_points'] as int;
      final currentLevel = profileResponse['level'] as int;

      // Calculate new level based on XP
      int newLevel = 1;
      if (currentXP >= 1000) newLevel = 5; // SALAAR
      else if (currentXP >= 700) newLevel = 4; // Shouryaanga
      else if (currentXP >= 300) newLevel = 3; // Mannarasi
      else if (currentXP >= 100) newLevel = 2; // Ghaniyaar
      else newLevel = 1; // The Beginning

      // Show level up popup if level increased
      if (newLevel > currentLevel) {
        String levelName = 'The Beginning';
        if (newLevel == 2) levelName = 'Ghaniyaar';
        else if (newLevel == 3) levelName = 'Mannarasi';
        else if (newLevel == 4) levelName = 'Shouryaanga';
        else if (newLevel == 5) levelName = 'SALAAR';

        showLevelUpPopup(
          context,
          newLevel: newLevel.toString(),
          levelName: levelName,
          newXP: newXP,
          totalXP: currentXP,
        );
      }
    } catch (e) {
      print('Error checking level up: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get nearby issues using the database function
  Future<List<Map<String, dynamic>>> getNearbyIssues(double latitude, double longitude, double radiusKm) async {
    try {
      final response = await _supabase.rpc('get_nearby_issues', params: {
        'user_lat': latitude,
        'user_lng': longitude,
        'radius_km': radiusKm,
      });
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching nearby issues: $e');
      return [];
    }
  }

  // Update issue status (for workers)
  Future<bool> updateIssueStatusForWorker(String issueId, String newStatus, String newPriority, [String? completionImageUrl]) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = _supabase.auth.currentUser;
      if (user == null) {
        _error = 'Please login to update issues';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Prepare update data
      Map<String, dynamic> updateData = {
        'status': newStatus,
        'priority': newPriority,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add completion image if provided
      if (completionImageUrl != null) {
        updateData['completion_image_url'] = completionImageUrl;
      }

      // Update the issue
      await _supabase.from('issues').update(updateData).eq('id', issueId);

      // If status is completed, give XP to the reporter and send notifications
      if (newStatus == 'completed') {
        try {
          // Get the issue to find the reporter and get issue details
          final issueResponse = await _supabase
              .from('issues')
              .select('user_id, issue_type')
              .eq('id', issueId)
              .single();

          final reporterId = issueResponse['user_id'];
          final issueTitle = issueResponse['issue_type'];
          
          // Get worker name for notification
          final workerResponse = await _supabase
              .from('profiles')
              .select('full_name')
              .eq('id', user.id)
              .single();
          final workerName = workerResponse['full_name'] ?? 'Worker';
          
          // Add XP for task completion using proper XP service
          await XPService.awardXPForAction(
            userId: reporterId,
            action: 'report_completed',
          );

          print('✅ Task completed - XP added to reporter via XPService');

          // Send Prabhas style task completion notification to user
          await PrabhasNotificationService.sendIssueCompletionToUser(
            workerName: workerName,
            issueTitle: issueTitle,
            issueId: issueId,
            userId: reporterId,
          );


          // XP notification is already sent above with task completion
        } catch (e) {
          print('Error adding XP and sending notifications: $e');
        }
      }

      // Refresh the issues list with real-time updates
      await fetchAllIssues(forceRefresh: true);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update issue: $e';
      print('Error updating issue: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}