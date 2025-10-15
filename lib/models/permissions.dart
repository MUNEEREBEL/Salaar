// lib/models/permissions.dart
class UserPermissions {
  final String userId;
  final bool canViewReports;
  final bool canEditReports;
  final bool canDeleteReports;
  final bool canAssignTasks;
  final bool canCreateWorkers;
  final bool canManageUsers;
  final bool canExportData;
  final bool canViewAnalytics;
  final bool canSendNotifications;
  final bool canModerateCommunity;
  final bool canAccessDeveloperTools;
  final DateTime updatedAt;

  UserPermissions({
    required this.userId,
    this.canViewReports = true,
    this.canEditReports = false,
    this.canDeleteReports = false,
    this.canAssignTasks = false,
    this.canCreateWorkers = false,
    this.canManageUsers = false,
    this.canExportData = false,
    this.canViewAnalytics = false,
    this.canSendNotifications = false,
    this.canModerateCommunity = false,
    this.canAccessDeveloperTools = false,
    required this.updatedAt,
  });

  factory UserPermissions.fromJson(Map<String, dynamic> json) {
    return UserPermissions(
      userId: json['user_id'] as String,
      canViewReports: json['can_view_reports'] as bool? ?? true,
      canEditReports: json['can_edit_reports'] as bool? ?? false,
      canDeleteReports: json['can_delete_reports'] as bool? ?? false,
      canAssignTasks: json['can_assign_tasks'] as bool? ?? false,
      canCreateWorkers: json['can_create_workers'] as bool? ?? false,
      canManageUsers: json['can_manage_users'] as bool? ?? false,
      canExportData: json['can_export_data'] as bool? ?? false,
      canViewAnalytics: json['can_view_analytics'] as bool? ?? false,
      canSendNotifications: json['can_send_notifications'] as bool? ?? false,
      canModerateCommunity: json['can_moderate_community'] as bool? ?? false,
      canAccessDeveloperTools: json['can_access_developer_tools'] as bool? ?? false,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'can_view_reports': canViewReports,
      'can_edit_reports': canEditReports,
      'can_delete_reports': canDeleteReports,
      'can_assign_tasks': canAssignTasks,
      'can_create_workers': canCreateWorkers,
      'can_manage_users': canManageUsers,
      'can_export_data': canExportData,
      'can_view_analytics': canViewAnalytics,
      'can_send_notifications': canSendNotifications,
      'can_moderate_community': canModerateCommunity,
      'can_access_developer_tools': canAccessDeveloperTools,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserPermissions copyWith({
    String? userId,
    bool? canViewReports,
    bool? canEditReports,
    bool? canDeleteReports,
    bool? canAssignTasks,
    bool? canCreateWorkers,
    bool? canManageUsers,
    bool? canExportData,
    bool? canViewAnalytics,
    bool? canSendNotifications,
    bool? canModerateCommunity,
    bool? canAccessDeveloperTools,
    DateTime? updatedAt,
  }) {
    return UserPermissions(
      userId: userId ?? this.userId,
      canViewReports: canViewReports ?? this.canViewReports,
      canEditReports: canEditReports ?? this.canEditReports,
      canDeleteReports: canDeleteReports ?? this.canDeleteReports,
      canAssignTasks: canAssignTasks ?? this.canAssignTasks,
      canCreateWorkers: canCreateWorkers ?? this.canCreateWorkers,
      canManageUsers: canManageUsers ?? this.canManageUsers,
      canExportData: canExportData ?? this.canExportData,
      canViewAnalytics: canViewAnalytics ?? this.canViewAnalytics,
      canSendNotifications: canSendNotifications ?? this.canSendNotifications,
      canModerateCommunity: canModerateCommunity ?? this.canModerateCommunity,
      canAccessDeveloperTools: canAccessDeveloperTools ?? this.canAccessDeveloperTools,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Predefined permission sets for different roles
  static UserPermissions getDefaultUserPermissions(String userId) {
    return UserPermissions(
      userId: userId,
      canViewReports: true,
      canEditReports: false,
      canDeleteReports: false,
      canAssignTasks: false,
      canCreateWorkers: false,
      canManageUsers: false,
      canExportData: false,
      canViewAnalytics: false,
      canSendNotifications: false,
      canModerateCommunity: false,
      canAccessDeveloperTools: false,
      updatedAt: DateTime.now(),
    );
  }

  static UserPermissions getDefaultWorkerPermissions(String userId) {
    return UserPermissions(
      userId: userId,
      canViewReports: true,
      canEditReports: true,
      canDeleteReports: false,
      canAssignTasks: false,
      canCreateWorkers: false,
      canManageUsers: false,
      canExportData: false,
      canViewAnalytics: true,
      canSendNotifications: false,
      canModerateCommunity: false,
      canAccessDeveloperTools: false,
      updatedAt: DateTime.now(),
    );
  }

  static UserPermissions getDefaultAdminPermissions(String userId) {
    return UserPermissions(
      userId: userId,
      canViewReports: true,
      canEditReports: true,
      canDeleteReports: true,
      canAssignTasks: true,
      canCreateWorkers: true,
      canManageUsers: true,
      canExportData: true,
      canViewAnalytics: true,
      canSendNotifications: true,
      canModerateCommunity: true,
      canAccessDeveloperTools: true,
      updatedAt: DateTime.now(),
    );
  }

  static UserPermissions getDefaultDeveloperPermissions(String userId) {
    return UserPermissions(
      userId: userId,
      canViewReports: true,
      canEditReports: true,
      canDeleteReports: true,
      canAssignTasks: true,
      canCreateWorkers: true,
      canManageUsers: true,
      canExportData: true,
      canViewAnalytics: true,
      canSendNotifications: true,
      canModerateCommunity: true,
      canAccessDeveloperTools: true,
      updatedAt: DateTime.now(),
    );
  }
}
