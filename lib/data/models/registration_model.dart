import '../../core/constants/app_constants.dart';

class Registration {
  final String id;
  final String studentId;
  final String programId;
  final String teamId;
  final String registrationNumber;
  final RegistrationStatus status;
  final DateTime createdAt;

  Registration({
    required this.id,
    required this.studentId,
    required this.programId,
    required this.teamId,
    required this.registrationNumber,
    this.status = RegistrationStatus.approved,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Registration copyWith({
    String? id,
    String? studentId,
    String? programId,
    String? teamId,
    String? registrationNumber,
    RegistrationStatus? status,
    DateTime? createdAt,
  }) {
    return Registration(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      programId: programId ?? this.programId,
      teamId: teamId ?? this.teamId,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'programId': programId,
      'teamId': teamId,
      'registrationNumber': registrationNumber,
      'status': status.name,
    };
  }

  factory Registration.fromMap(Map<String, dynamic> map) {
    return Registration(
      id: map['id']?.toString() ?? '',
      studentId: (map['studentId'] ?? map['student_id'])?.toString() ?? '',
      programId: (map['programId'] ?? map['program_id'])?.toString() ?? '',
      teamId: (map['teamId'] ?? map['team_id'])?.toString() ?? '',
      registrationNumber: (map['registrationNumber'] ??
              map['registration_number'] ??
              map['regNumber'] ??
              map['reg_number'])
          ?.toString() ??
          '',
      status: RegistrationStatus.fromString(map['status']?.toString() ?? 'approved'),
      createdAt: map['createdAt'] != null
          ? (DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now())
          : (map['created_at'] != null
              ? (DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now())
              : DateTime.now()),
    );
  }
}
