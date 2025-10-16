// lib/providers/community_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityUser {
  final String id;
  final String? fullName;
  final int issuesReported;
  final int expPoints;

  CommunityUser({
    required this.id,
    this.fullName,
    required this.issuesReported,
    required this.expPoints,
  });

  factory CommunityUser.fromJson(Map<String, dynamic> json) {
    return CommunityUser(
      id: json['id'],
      fullName: json['full_name'],
      issuesReported: 0, // Default value since column doesn't exist
      expPoints: json['xp'] ?? 0,
    );
  }
}

class CommunityDiscussion {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String? authorName;
  final int commentCount;
  final int likeCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<DiscussionReply> replies;

  CommunityDiscussion({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    this.authorName,
    required this.commentCount,
    required this.likeCount,
    required this.createdAt,
    required this.updatedAt,
    this.replies = const [],
  });

  factory CommunityDiscussion.fromJson(Map<String, dynamic> json) {
    return CommunityDiscussion(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      authorId: json['user_id'] ?? json['author_id'], // Handle both column names
      authorName: json['profiles']?['full_name'] ?? 'Unknown User',
      commentCount: json['comment_count'] ?? 0, // Will be 0 if column doesn't exist
      likeCount: json['like_count'] ?? 0, // Will be 0 if column doesn't exist
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      replies: List<DiscussionReply>.from(
        (json['replies'] ?? []).map((x) => DiscussionReply.fromJson(x))
      ),
    );
  }
}

class DiscussionReply {
  final String id;
  final String discussionId;
  final String authorId;
  final String? authorName;
  final String content;
  final int likeCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  DiscussionReply({
    required this.id,
    required this.discussionId,
    required this.authorId,
    this.authorName,
    required this.content,
    required this.likeCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DiscussionReply.fromJson(Map<String, dynamic> json) {
    return DiscussionReply(
      id: json['id'],
      discussionId: json['discussion_id'],
      authorId: json['author_id'],
      authorName: json['profiles']?['full_name'],
      content: json['content'],
      likeCount: json['like_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'discussion_id': discussionId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class CommunityProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<CommunityUser> _leaderboard = [];
  List<CommunityDiscussion> _discussions = [];
  Map<String, List<DiscussionReply>> _discussionReplies = {};
  bool _isLoading = false;
  String? _error;

  List<CommunityUser> get leaderboard => _leaderboard;
  List<CommunityDiscussion> get discussions => _discussions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch leaderboard data
  Future<void> fetchLeaderboard() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _supabase
          .from('profiles')
          .select('id, full_name, xp')
          .order('xp', ascending: false)
          .limit(20);

      _leaderboard = (response as List)
          .map((data) => CommunityUser.fromJson(data))
          .toList();
    } catch (e) {
      _error = 'Failed to load leaderboard: $e';
      print('Error fetching leaderboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch community discussions with replies
  Future<void> fetchDiscussions() async {
    try {
      // Don't set loading to true here to avoid blocking UI
      _error = null;

            // Try to fetch from discussions table directly (without comment_count as it doesn't exist)
            final response = await _supabase
                .from('discussions')
                .select('id, title, content, user_id, created_at, updated_at')
                .order('created_at', ascending: false)
                .limit(20);

      _discussions = (response as List)
          .map((data) => CommunityDiscussion.fromJson(data))
          .toList();

      // Cache replies separately for easy access
      for (final discussion in _discussions) {
        _discussionReplies[discussion.id] = discussion.replies;
      }

    } catch (e) {
      _error = 'Failed to load discussions: $e';
      print('Error fetching discussions: $e');
      // Set empty list if error
      _discussions = [];
    } finally {
      notifyListeners();
    }
  }

  // Fetch replies for a specific discussion
  Future<void> fetchReplies(String discussionId) async {
    try {
      final response = await _supabase
          .from('discussion_replies')
          .select('*, profiles(full_name)')
          .eq('discussion_id', discussionId)
          .order('created_at', ascending: true);

      final replies = (response as List)
          .map((data) => DiscussionReply.fromJson(data))
          .toList();

      _discussionReplies[discussionId] = replies;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load replies: $e';
      print('Error fetching replies: $e');
    }
  }

  // Create new discussion
  Future<bool> createDiscussion(String title, String content) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase.from('discussions').insert({
        'title': title,
        'content': content,
        'author_id': user.id,
        'comment_count': 0,
        'like_count': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      await fetchDiscussions();
      return true;
    } catch (e) {
      _error = 'Failed to create discussion: $e';
      notifyListeners();
      return false;
    }
  }

  // Add reply to discussion
  Future<bool> addReply(String discussionId, String content) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase.from('discussion_replies').insert({
        'discussion_id': discussionId,
        'author_id': user.id,
        'content': content,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Update comment count
      await _supabase
          .from('discussions')
          .update({'comment_count': _supabase.rpc('increment', params: {'x': 1})})
          .eq('id', discussionId);

      // Refresh replies
      await fetchReplies(discussionId);
      await fetchDiscussions(); // Refresh discussions to update comment count

      return true;
    } catch (e) {
      _error = 'Failed to add reply: $e';
      notifyListeners();
      return false;
    }
  }

  // Like a discussion
  Future<bool> likeDiscussion(String discussionId) async {
    try {
      await _supabase
          .from('discussions')
          .update({'like_count': _supabase.rpc('increment', params: {'x': 1})})
          .eq('id', discussionId);

      await fetchDiscussions();
      return true;
    } catch (e) {
      _error = 'Failed to like discussion: $e';
      return false;
    }
  }

  // Like a reply
  Future<bool> likeReply(String replyId) async {
    try {
      await _supabase
          .from('discussion_replies')
          .update({'like_count': _supabase.rpc('increment', params: {'x': 1})})
          .eq('id', replyId);

      // Find which discussion this reply belongs to and refresh its replies
      for (final discussion in _discussions) {
        if (_discussionReplies[discussion.id]?.any((reply) => reply.id == replyId) == true) {
          await fetchReplies(discussion.id);
          break;
        }
      }

      return true;
    } catch (e) {
      _error = 'Failed to like reply: $e';
      return false;
    }
  }

  List<DiscussionReply> getReplies(String discussionId) {
    return _discussionReplies[discussionId] ?? [];
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}