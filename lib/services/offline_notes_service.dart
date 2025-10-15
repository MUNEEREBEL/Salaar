// lib/services/offline_notes_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OfflineNote {
  final String id;
  final String taskId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final String? userId;

  OfflineNote({
    required this.id,
    required this.taskId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced,
      'user_id': userId,
    };
  }

  factory OfflineNote.fromJson(Map<String, dynamic> json) {
    return OfflineNote(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isSynced: json['is_synced'] as bool? ?? false,
      userId: json['user_id'] as String?,
    );
  }

  OfflineNote copyWith({
    String? id,
    String? taskId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? userId,
  }) {
    return OfflineNote(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      userId: userId ?? this.userId,
    );
  }
}

class OfflineNotesService {
  static const String _notesKey = 'offline_notes';
  static const String _syncQueueKey = 'sync_queue';
  static const String _lastSyncKey = 'last_sync';
  
  final SupabaseClient _supabase = Supabase.instance.client;
  final List<OfflineNote> _notes = [];
  final List<OfflineNote> _syncQueue = [];
  
  bool _isInitialized = false;
  bool _isOnline = true;
  Timer? _syncTimer;

  // Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await _loadNotesFromStorage();
    await _loadSyncQueueFromStorage();
    _startPeriodicSync();
    _isInitialized = true;
  }

  // Check if device is online
  Future<bool> get isOnline async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Add a new note
  Future<String> addNote(String taskId, String content) async {
    final noteId = DateTime.now().millisecondsSinceEpoch.toString();
    final userId = _supabase.auth.currentUser?.id;
    
    final note = OfflineNote(
      id: noteId,
      taskId: taskId,
      content: content,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isSynced: false,
      userId: userId,
    );

    _notes.add(note);
    await _saveNotesToStorage();
    
    // Try to sync immediately if online
    if (await isOnline) {
      await _syncNote(note);
    } else {
      _syncQueue.add(note);
      await _saveSyncQueueToStorage();
    }

    return noteId;
  }

  // Update an existing note
  Future<void> updateNote(String noteId, String content) async {
    final noteIndex = _notes.indexWhere((note) => note.id == noteId);
    if (noteIndex == -1) return;

    final updatedNote = _notes[noteIndex].copyWith(
      content: content,
      updatedAt: DateTime.now(),
      isSynced: false,
    );

    _notes[noteIndex] = updatedNote;
    await _saveNotesToStorage();

    // Try to sync immediately if online
    if (await isOnline) {
      await _syncNote(updatedNote);
    } else {
      _addToSyncQueue(updatedNote);
    }
  }

  // Delete a note
  Future<void> deleteNote(String noteId) async {
    _notes.removeWhere((note) => note.id == noteId);
    _syncQueue.removeWhere((note) => note.id == noteId);
    
    await _saveNotesToStorage();
    await _saveSyncQueueToStorage();

    // Try to sync deletion if online
    if (await isOnline) {
      await _syncNoteDeletion(noteId);
    }
  }

  // Get notes for a specific task
  List<OfflineNote> getNotesForTask(String taskId) {
    return _notes.where((note) => note.taskId == taskId).toList();
  }

  // Get all notes
  List<OfflineNote> getAllNotes() {
    return List.from(_notes);
  }

  // Get unsynced notes
  List<OfflineNote> getUnsyncedNotes() {
    return _notes.where((note) => !note.isSynced).toList();
  }

  // Sync all pending notes
  Future<void> syncAllNotes() async {
    if (!await isOnline) return;

    final unsyncedNotes = getUnsyncedNotes();
    for (final note in unsyncedNotes) {
      await _syncNote(note);
    }

    // Sync queued notes
    for (final note in List.from(_syncQueue)) {
      await _syncNote(note);
    }

    await _saveNotesToStorage();
    await _saveSyncQueueToStorage();
  }

  // Sync a single note
  Future<void> _syncNote(OfflineNote note) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Check if note already exists in database
      final existingNotes = await _supabase
          .from('task_notes')
          .select()
          .eq('id', note.id)
          .eq('user_id', userId);

      if (existingNotes.isNotEmpty) {
        // Update existing note
        await _supabase
            .from('task_notes')
            .update({
              'content': note.content,
              'updated_at': note.updatedAt.toIso8601String(),
            })
            .eq('id', note.id)
            .eq('user_id', userId);
      } else {
        // Insert new note
        await _supabase
            .from('task_notes')
            .insert({
              'id': note.id,
              'task_id': note.taskId,
              'content': note.content,
              'user_id': userId,
              'created_at': note.createdAt.toIso8601String(),
              'updated_at': note.updatedAt.toIso8601String(),
            });
      }

      // Mark as synced
      final noteIndex = _notes.indexWhere((n) => n.id == note.id);
      if (noteIndex != -1) {
        _notes[noteIndex] = note.copyWith(isSynced: true);
      }

      // Remove from sync queue
      _syncQueue.removeWhere((n) => n.id == note.id);

      await _saveNotesToStorage();
      await _saveSyncQueueToStorage();
    } catch (e) {
      print('Error syncing note: $e');
      // Keep note in sync queue for retry
      _addToSyncQueue(note);
    }
  }

  // Sync note deletion
  Future<void> _syncNoteDeletion(String noteId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('task_notes')
          .delete()
          .eq('id', noteId)
          .eq('user_id', userId);
    } catch (e) {
      print('Error syncing note deletion: $e');
    }
  }

  // Add note to sync queue
  void _addToSyncQueue(OfflineNote note) {
    final existingIndex = _syncQueue.indexWhere((n) => n.id == note.id);
    if (existingIndex != -1) {
      _syncQueue[existingIndex] = note;
    } else {
      _syncQueue.add(note);
    }
  }

  // Start periodic sync
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (await isOnline) {
        await syncAllNotes();
      }
    });
  }

  // Load notes from local storage
  Future<void> _loadNotesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey);
      if (notesJson != null) {
        final List<dynamic> notesList = json.decode(notesJson);
        _notes.clear();
        _notes.addAll(
          notesList.map((json) => OfflineNote.fromJson(json as Map<String, dynamic>))
        );
      }
    } catch (e) {
      print('Error loading notes from storage: $e');
    }
  }

  // Save notes to local storage
  Future<void> _saveNotesToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = json.encode(_notes.map((note) => note.toJson()).toList());
      await prefs.setString(_notesKey, notesJson);
    } catch (e) {
      print('Error saving notes to storage: $e');
    }
  }

  // Load sync queue from local storage
  Future<void> _loadSyncQueueFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_syncQueueKey);
      if (queueJson != null) {
        final List<dynamic> queueList = json.decode(queueJson);
        _syncQueue.clear();
        _syncQueue.addAll(
          queueList.map((json) => OfflineNote.fromJson(json as Map<String, dynamic>))
        );
      }
    } catch (e) {
      print('Error loading sync queue from storage: $e');
    }
  }

  // Save sync queue to local storage
  Future<void> _saveSyncQueueToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = json.encode(_syncQueue.map((note) => note.toJson()).toList());
      await prefs.setString(_syncQueueKey, queueJson);
    } catch (e) {
      print('Error saving sync queue to storage: $e');
    }
  }

  // Get sync status
  Map<String, dynamic> getSyncStatus() {
    return {
      'total_notes': _notes.length,
      'synced_notes': _notes.where((note) => note.isSynced).length,
      'unsynced_notes': _notes.where((note) => !note.isSynced).length,
      'queued_notes': _syncQueue.length,
      'is_online': _isOnline,
    };
  }

  // Clear all notes (for testing)
  Future<void> clearAllNotes() async {
    _notes.clear();
    _syncQueue.clear();
    await _saveNotesToStorage();
    await _saveSyncQueueToStorage();
  }

  // Dispose resources
  void dispose() {
    _syncTimer?.cancel();
  }
}
