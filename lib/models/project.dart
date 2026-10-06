import 'package:equatable/equatable.dart';

/// Represents a BeemView project.
///
/// Used in both the projects list and as a nested association
/// inside task responses.
class Project extends Equatable {
  final int id;
  final String name;

  const Project({
    required this.id,
    required this.name,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  @override
  List<Object?> get props => [id, name];
}
