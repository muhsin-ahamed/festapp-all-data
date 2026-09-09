class Schedule {
  final String id;
  final String programId;
  final String venueId;
  final String date; // YYYY-MM-DD
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final String status; // SCHEDULED, IN_PROGRESS, COMPLETED, CANCELLED

  Schedule({
    required this.id,
    required this.programId,
    required this.venueId,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.status = 'SCHEDULED',
  });

  Schedule copyWith({
    String? id,
    String? programId,
    String? venueId,
    String? date,
    String? startTime,
    String? endTime,
    String? status,
  }) {
    return Schedule(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      venueId: venueId ?? this.venueId,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'programId': programId,
      'venueId': venueId,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
    };
  }

  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id']?.toString() ?? '',
      programId: (map['programId'] ?? map['program_id'])?.toString() ?? '',
      venueId: (map['venueId'] ?? map['venue_id'])?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      startTime: (map['startTime'] ?? map['start_time'])?.toString() ?? '',
      endTime: (map['endTime'] ?? map['end_time'])?.toString() ?? '',
      status: map['status']?.toString() ?? 'SCHEDULED',
    );
  }
}
