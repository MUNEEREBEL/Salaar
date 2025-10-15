// lib/models/user.dart
class SalaarUser {
  final String id;
  final String role;
  final String fullName;
  final String username;
  final String email;
  final int expPoints;
  final int issuesReported;
  final int issuesVerified;
  final String? bio;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? department;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SalaarUser({
    required this.id,
    required this.role,
    required this.fullName,
    required this.username,
    required this.email,
    required this.expPoints,
    required this.issuesReported,
    required this.issuesVerified,
    this.bio,
    this.phoneNumber,
    this.profileImageUrl,
    this.department,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SalaarUser.fromJson(Map<String, dynamic> json) {
    return SalaarUser(
      id: json['id'] ?? '',
      role: json['role'] ?? 'user',
      fullName: json['full_name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      expPoints: json['exp_points'] ?? 0,
      issuesReported: json['issues_reported'] ?? 0,
      issuesVerified: json['issues_verified'] ?? 0,
      bio: json['bio'],
      phoneNumber: json['phone_number'],
      profileImageUrl: json['profile_image_url'],
      department: json['department'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'full_name': fullName,
      'username': username,
      'email': email,
      'exp_points': expPoints,
      'issues_reported': issuesReported,
      'issues_verified': issuesVerified,
      'bio': bio,
      'phone_number': phoneNumber,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SalaarUser copyWith({
    String? id,
    String? role,
    String? fullName,
    String? username,
    String? email,
    int? expPoints,
    int? issuesReported,
    int? issuesVerified,
    String? bio,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SalaarUser(
      id: id ?? this.id,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      expPoints: expPoints ?? this.expPoints,
      issuesReported: issuesReported ?? this.issuesReported,
      issuesVerified: issuesVerified ?? this.issuesVerified,
      bio: bio ?? this.bio,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get levelName {
    if (expPoints >= 1000) return 'SALAAR';
    if (expPoints >= 700) return 'Shouryaanga';
    if (expPoints >= 300) return 'Mannarasi';
    if (expPoints >= 100) return 'Ghaniyaar';
    return 'The Beginning';
  }

  int get level {
    if (expPoints >= 1000) return 5;
    if (expPoints >= 700) return 4;
    if (expPoints >= 300) return 3;
    if (expPoints >= 100) return 2;
    return 1;
  }

  bool get isAdmin => role == 'admin';
  bool get isWorker => role == 'worker';
  bool get isDeveloper => role == 'developer';
  bool get isUser => role == 'user';
}
