class TeamLeader {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String username;
  final String password;
  final String teamId;
  final String status; // ACTIVE, INACTIVE

  TeamLeader({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.username,
    required this.password,
    required this.teamId,
    this.status = 'ACTIVE',
  });

  TeamLeader copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? username,
    String? password,
    String? teamId,
    String? status,
  }) {
    return TeamLeader(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      username: username ?? this.username,
      password: password ?? this.password,
      teamId: teamId ?? this.teamId,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'username': username,
      'password': password,
      'teamId': teamId,
      'status': status,
    };
  }

  factory TeamLeader.fromMap(Map<String, dynamic> map) {
    return TeamLeader(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      teamId: map['teamId'] ?? '',
      status: map['status'] ?? 'ACTIVE',
    );
  }
}
