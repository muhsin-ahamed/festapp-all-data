import '../../core/constants/app_constants.dart';

class User {
  final String id;
  final String username;
  final String password; // In production this would be hashed
  final String name;
  final UserRole role;
  final String? teamId; // Set if role is teamLeader
  final String? juryId; // Set if role is jury
  final DateTime createdAt;

  User({
    required this.id,
    required this.username,
    required this.password,
    required this.name,
    required this.role,
    this.teamId,
    this.juryId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  User copyWith({
    String? id,
    String? username,
    String? password,
    String? name,
    UserRole? role,
    String? teamId,
    String? juryId,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      name: name ?? this.name,
      role: role ?? this.role,
      teamId: teamId ?? this.teamId,
      juryId: juryId ?? this.juryId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'name': name,
      'role': role.code,
      'teamId': teamId,
      'juryId': juryId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      name: map['name'] ?? '',
      role: UserRole.fromCode(map['role'] ?? '') ?? UserRole.festController,
      teamId: map['teamId'],
      juryId: map['juryId'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
