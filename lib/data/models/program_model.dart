import '../../core/constants/app_constants.dart';

class Program {
  final String id;
  final String programCode;
  final String programName;
  final FestSection section;
  final ProgramCategory category;
  final bool isStageProgram;
  final bool isGeneral;
  final int maxParticipants;
  final String duration; // e.g. "30 mins" or "1 hour"
  final String? venueId;
  final String? scheduleId;
  final String? rules;
  final String status; // UPCOMING, IN_PROGRESS, COMPLETED

  Program({
    required this.id,
    required this.programCode,
    required this.programName,
    required this.section,
    required this.category,
    required this.isStageProgram,
    required this.isGeneral,
    this.maxParticipants = 1,
    this.duration = '30 mins',
    this.venueId,
    this.scheduleId,
    this.rules,
    this.status = 'UPCOMING',
  });

  Program copyWith({
    String? id,
    String? programCode,
    String? programName,
    FestSection? section,
    ProgramCategory? category,
    bool? isStageProgram,
    bool? isGeneral,
    int? maxParticipants,
    String? duration,
    String? venueId,
    String? scheduleId,
    String? rules,
    String? status,
  }) {
    return Program(
      id: id ?? this.id,
      programCode: programCode ?? this.programCode,
      programName: programName ?? this.programName,
      section: section ?? this.section,
      category: category ?? this.category,
      isStageProgram: isStageProgram ?? this.isStageProgram,
      isGeneral: isGeneral ?? this.isGeneral,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      duration: duration ?? this.duration,
      venueId: venueId ?? this.venueId,
      scheduleId: scheduleId ?? this.scheduleId,
      rules: rules ?? this.rules,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'programCode': programCode,
      'programName': programName,
      'section': section.name,
      'category': category.name,
      'isStageProgram': isStageProgram,
      'isGeneral': isGeneral,
      'maxParticipants': maxParticipants,
      'duration': duration,
      'venueId': venueId,
      'scheduleId': scheduleId,
      'rules': rules,
      'status': status,
    };
  }

  factory Program.fromMap(Map<String, dynamic> map) {
    final sec = FestSection.fromString(map['section'] ?? 'junior');
    final cat = ProgramCategory.fromString(map['category'] ?? 'stage');
    final isStage = map['isStageProgram'] ?? (cat == ProgramCategory.stage);
    final isGen = map['isGeneral'] ?? (sec == FestSection.general);

    return Program(
      id: map['id'] ?? '',
      programCode: map['programCode'] ?? '',
      programName: map['programName'] ?? '',
      section: sec,
      category: cat,
      isStageProgram: isStage,
      isGeneral: isGen,
      maxParticipants: map['maxParticipants'] ?? 1,
      duration: map['duration'] ?? '30 mins',
      venueId: map['venueId'],
      scheduleId: map['scheduleId'],
      rules: map['rules'],
      status: map['status'] ?? 'UPCOMING',
    );
  }
}
