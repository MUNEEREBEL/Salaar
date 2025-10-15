// lib/services/realtime_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class RealtimeService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static RealtimeChannel? _issuesChannel;
  static RealtimeChannel? _announcementsChannel;
  static RealtimeChannel? _locationsChannel;

  static void initializeRealtimeListeners(String userId) {
    _listenToIssueUpdates(userId);
    _listenToAnnouncements();
    _listenToLocationUpdates(userId);
  }

  static void _listenToIssueUpdates(String userId) {
    _issuesChannel = _supabase.channel('issues-$userId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'issues',
        callback: (payload) {
          try {
            final evt = payload.eventType;
            final newData = (payload.newRecord ?? {}) as Map<String, dynamic>;
            if (evt == PostgresChangeEvent.insert && (newData['user_id'] == userId)) {
              NotificationService.showStatusUpdateNotification(
                issueTitle: newData['issue_type'] ?? 'Issue',
                oldStatus: 'created',
                newStatus: newData['status'] ?? 'pending',
                issueId: newData['id'] ?? '',
              );
            }
            if (evt == PostgresChangeEvent.update && (newData['assignee_id'] == userId)) {
              NotificationService.showTaskAssignedNotification(
                issueTitle: newData['issue_type'] ?? 'Issue',
                location: newData['address'] ?? 'Unknown location',
                issueId: newData['id'] ?? '',
              );
            }
          } catch (_) {}
        },
      )
      ..subscribe();
  }

  static void _listenToAnnouncements() {
    _announcementsChannel = _supabase.channel('announcements')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'announcements',
        callback: (payload) {
          try {
            final newData = (payload.newRecord ?? {}) as Map<String, dynamic>;
            if (newData['is_active'] == true) {
              NotificationService.showAnnouncementNotification(
                title: (newData['title'] ?? 'Announcement').toString(),
                content: (newData['content'] ?? '').toString(),
              );
            }
          } catch (_) {}
        },
      )
      ..subscribe();
  }

  static void _listenToLocationUpdates(String userId) {
    _locationsChannel = _supabase.channel('locations-$userId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'worker_locations',
        callback: (payload) {
          // Optionally: forward to in-app streams
        },
      )
      ..subscribe();
  }

  static void dispose() {
    _issuesChannel?.unsubscribe();
    _announcementsChannel?.unsubscribe();
    _locationsChannel?.unsubscribe();
  }
}