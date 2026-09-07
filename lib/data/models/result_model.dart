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
      id: map['id'] ?? '',
      programId: map['programId'] ?? '',
      studentId: map['studentId'] ?? '',
      teamId: map['teamId'] ?? '',
      juryId: map['juryId'],
      marks: (map['marks'] as num?)?.toDouble() ?? 0.0,
      grade: map['grade'] ?? '',
      position: map['position'] as int?,
      points: map['points'] ?? 0,
      remarks: map['remarks'],
      status: ResultStatus.fromString(map['status'] ?? 'draft'),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : DateTime.now(),
      publishedAt: map['publishedAt'] != null
          ? DateTime.parse(map['publishedAt'])
          : null,
    );
  }
}
