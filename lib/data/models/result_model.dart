import '../../core/constants/app_constants.dart';

class Result {
  final String id;
  final String programId;
  final String studentId;
  final String teamId;
  final String? juryId;
  final double marks;
  final String grade; // A, B, C, etc.
  final int? position; // 1, 2, 3 or null
  final int points;
  final String? remarks;
  final ResultStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;

  Result({
    required this.id,
    required this.programId,
    required this.studentId,
    required this.teamId,
    this.juryId,
    this.marks = 0.0,
    this.grade = '',
    this.position,
    this.points = 0,
    this.remarks,
    this.status = ResultStatus.draft,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.publishedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Result copyWith({
    String? id,
    String? programId,
    String? studentId,
    String? teamId,
    String? juryId,
    double? marks,
    String? grade,
    int? position,
    int? points,
    String? remarks,
    ResultStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
  }) {
    return Result(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      studentId: studentId ?? this.studentId,
      teamId: teamId ?? this.teamId,
      juryId: juryId ?? this.juryId,
      marks: marks ?? this.marks,
      grade: grade ?? this.grade,
      position: position ?? this.position,
      points: points ?? this.points,
      remarks: remarks ?? this.remarks,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      publishedAt: publishedAt ?? this.publishedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'programId': programId,
      'studentId': studentId,
      'teamId': teamId,
      'juryId': juryId,
      'marks': marks,
      'grade': grade,
      'position': position,
      'points': points,
      'remarks': remarks,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'publishedAt': publishedAt?.toIso8601String(),
    };
  }

  factory Result.fromMap(Map<String, dynamic> map) {
    return Result(
      id: map['id']?.toString() ?? '',
      programId: (map['programId'] ?? map['program_id'])?.toString() ?? '',
      studentId: (map['studentId'] ?? map['student_id'])?.toString() ?? '',
      teamId: (map['teamId'] ?? map['team_id'])?.toString() ?? '',
      juryId: (map['juryId'] ?? map['jury_id'])?.toString(),
      marks: (map['marks'] as num?)?.toDouble() ?? 0.0,
      grade: map['grade']?.toString() ?? '',
      position: map['position'] as int?,
      points: (map['points'] as num?)?.toInt() ?? 0,
      remarks: map['remarks']?.toString(),
      status: ResultStatus.fromString(map['status']?.toString() ?? 'draft'),
      createdAt: map['createdAt'] != null
          ? (DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now())
          : (map['created_at'] != null
              ? (DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now())
              : DateTime.now()),
      updatedAt: map['updatedAt'] != null
          ? (DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now())
          : (map['updated_at'] != null
              ? (DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now())
              : DateTime.now()),
      publishedAt: map['publishedAt'] != null
          ? DateTime.tryParse(map['publishedAt'].toString())
          : (map['published_at'] != null
              ? DateTime.tryParse(map['published_at'].toString())
              : null),
    );
  }
}
