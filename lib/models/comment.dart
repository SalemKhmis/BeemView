import 'package:equatable/equatable.dart';

import 'user.dart';

/// Represents a comment on a task.
///
/// Comments are returned as part of task details in the `Comments` array.
/// Each comment has a nested `user` object.
class Comment extends Equatable {
  final int id;
  final String content;
  final User? user;
  final DateTime? createdAt;

  const Comment({
    required this.id,
    required this.content,
    this.user,
    this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      content: json['content'] as String? ?? '',
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      createdAt: _parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      if (user != null) 'user': user!.toJson(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  @override
  List<Object?> get props => [id, content, user, createdAt];
}
