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
      'duration': duration,
      'venueId': venueId,
      'scheduleId': scheduleId,
      'status': status,
    };
  }

  factory Program.fromMap(Map<String, dynamic> map) {
    final sec = FestSection.fromString((map['section'] ?? map['fest_section'] ?? 'subJunior').toString());
    final cat = ProgramCategory.fromString((map['category'] ?? map['program_category'] ?? 'stage').toString());
    final rawIsStage = map['isStageProgram'] ?? map['is_stage_program'];
    final isStage = rawIsStage is bool ? rawIsStage : (rawIsStage?.toString() == 'true' || cat == ProgramCategory.stage);
    final rawIsGen = map['isGeneral'] ?? map['is_general'];
    final isGen = rawIsGen is bool ? rawIsGen : (rawIsGen?.toString() == 'true' || sec == FestSection.general || cat == ProgramCategory.general);

    return Program(
      id: (map['id'] ?? '').toString(),
      programCode: (map['programCode'] ?? map['program_code'] ?? '').toString(),
      programName: (map['programName'] ?? map['program_name'] ?? '').toString(),
      section: sec,
      category: cat,
      isStageProgram: isStage,
      isGeneral: isGen,
      maxParticipants: int.tryParse((map['maxParticipants'] ?? map['max_participants'] ?? 1).toString()) ?? 1,
      duration: (map['duration'] ?? '30 mins').toString(),
      venueId: map['venueId']?.toString() ?? map['venue_id']?.toString(),
      scheduleId: map['scheduleId']?.toString() ?? map['schedule_id']?.toString(),
      rules: map['rules']?.toString(),
      status: (map['status'] ?? 'UPCOMING').toString(),
    );
  }
}
