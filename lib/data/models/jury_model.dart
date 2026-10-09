class Jury {
  final String id;
  final String name;
  final String username;
  final String password;
  final String juryCode;
  final List<String> assignedPrograms; // list of program IDs
  final String status; // ACTIVE, INACTIVE

  Jury({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.juryCode,
    required this.assignedPrograms,
    this.status = 'ACTIVE',
  });

  Jury copyWith({
    String? id,
    String? name,
    String? username,
    String? password,
    String? juryCode,
    List<String>? assignedPrograms,
    String? status,
  }) {
    return Jury(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      password: password ?? this.password,
      juryCode: juryCode ?? this.juryCode,
      assignedPrograms: assignedPrograms ?? this.assignedPrograms,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap({bool includeStatus = false}) {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'username': username,
      'password': password,
      'juryCode': juryCode,
      'assignedPrograms': assignedPrograms,
    };
    if (includeStatus) {
      map['status'] = status;
    }
    return map;
  }

  factory Jury.fromMap(Map<String, dynamic> map) {
    return Jury(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      juryCode: map['juryCode'] ?? map['jury_code'] ?? '',
      assignedPrograms: List<String>.from(
        map['assignedPrograms'] ?? map['assigned_programs'] ?? [],
      ),
      status: map['status'] ?? 'ACTIVE',
    );
  }
}
