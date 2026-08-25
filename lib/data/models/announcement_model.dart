class Announcement {
  final String id;
  final String? programId;
  final String? resultId;
  final String title;
  final String message;
  final String status; // DRAFT, ANNOUNCED, ARCHIVED
  final DateTime createdAt;
  final DateTime? announcedAt;

  Announcement({
    required this.id,
    this.programId,
    this.resultId,
    required this.title,
    required this.message,
    this.status = 'ANNOUNCED',
    DateTime? createdAt,
    this.announcedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Announcement copyWith({
    String? id,
    String? programId,
    String? resultId,
    String? title,
    String? message,
    String? status,
    DateTime? createdAt,
    DateTime? announcedAt,
  }) {
    return Announcement(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      resultId: resultId ?? this.resultId,
      title: title ?? this.title,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      announcedAt: announcedAt ?? this.announcedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'programId': programId,
      'resultId': resultId,
      'title': title,
      'message': message,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'announcedAt': announcedAt?.toIso8601String(),
    };
  }

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'] ?? '',
      programId: map['programId'],
      resultId: map['resultId'],
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      status: map['status'] ?? 'ANNOUNCED',
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
      announcedAt: map['announcedAt'] != null ? DateTime.parse(map['announcedAt']) : null,
    );
  }
}
