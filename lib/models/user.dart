import 'package:equatable/equatable.dart';

/// Represents a BeemView user.
///
/// Used for the authenticated user profile and in task assignees/comments.
/// The API returns `full_name` as the display name.
class User extends Equatable {
  final int id;
  final String fullName;
  final String? email;
  final String? phone;
  final String? role;
  final String? avatar;
  final String? jobTitle;
  final String? department;
  final String? status;
  final String? createdAt;

  const User({
    required this.id,
    required this.fullName,
    this.email,
    this.phone,
    this.role,
    this.avatar,
    this.jobTitle,
    this.department,
    this.status,
    this.createdAt,
  });

  /// Parses a user from JSON.
  ///
  /// Handles shapes:
  /// - Profile response `/api/users/me/profile`
  /// - Login response `{"id": 12, "full_name": "Name", "email": "..."}`
  /// - Comment user: `{"id": 12, "name": "Name"}`
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      fullName: (json['full_name'] as String?) ??
          (json['name'] as String?) ??
          (json['username'] as String?) ??
          'Unknown',
      email: json['email'] as String?,
      phone: (json['phone'] as String?) ?? (json['phone_number'] as String?),
      role: (json['role'] as String?) ?? (json['role_name'] as String?),
      avatar: (json['avatar'] as String?) ??
          (json['avatar_url'] as String?) ??
          (json['image'] as String?),
      jobTitle: (json['job_title'] as String?) ??
          (json['title'] as String?) ??
          (json['position'] as String?),
      department: (json['department'] as String?) ??
          (json['department_name'] as String?),
      status: json['status'] as String?,
      createdAt: (json['created_at'] as String?) ??
          (json['joined_at'] as String?) ??
          (json['date_joined'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (role != null) 'role': role,
      if (avatar != null) 'avatar': avatar,
      if (jobTitle != null) 'job_title': jobTitle,
      if (department != null) 'department': department,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  User copyWith({
    int? id,
    String? fullName,
    String? email,
    String? phone,
    String? role,
    String? avatar,
    String? jobTitle,
    String? department,
    String? status,
    String? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      jobTitle: jobTitle ?? this.jobTitle,
      department: department ?? this.department,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        phone,
        role,
        avatar,
        jobTitle,
        department,
        status,
        createdAt,
      ];
}
