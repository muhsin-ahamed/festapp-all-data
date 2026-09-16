import 'dart:convert';

class TvSettings {
  final String id;
  // Modes: 'ONLY_MAIN' (or 'POSTER'), 'AUTO_WITH_SCOREBOARD', 'AUTO_WITHOUT_SCOREBOARD', 'ANNOUNCE_RESULT', 'SCOREBOARD', 'RESULTS'
  final String screenMode;
  final int slideDuration; // in seconds, default 15
  final int currentSlide;
  final bool autoRotate;
  final bool showTeamScores;
  final bool showResults;
  final bool showAnnouncements;
  final String? customMessage;

  // New fields for Announce Result Mode
  final String? announcedProgramId;
  final int? announcedResultNumber;
  final List<int> revealedPositions; // e.g. [3], [3, 2], [3, 2, 1]

  TvSettings({
    this.id = 'default_tv_settings',
    this.screenMode = 'ONLY_MAIN',
    this.slideDuration = 15,
    this.currentSlide = 0,
    this.autoRotate = true,
    this.showTeamScores = true,
    this.showResults = true,
    this.showAnnouncements = true,
    this.customMessage,
    this.announcedProgramId,
    this.announcedResultNumber,
    this.revealedPositions = const [],
  });

  TvSettings copyWith({
    String? id,
    String? screenMode,
    int? slideDuration,
    int? currentSlide,
    bool? autoRotate,
    bool? showTeamScores,
    bool? showResults,
    bool? showAnnouncements,
    String? customMessage,
    String? announcedProgramId,
    int? announcedResultNumber,
    List<int>? revealedPositions,
  }) {
    return TvSettings(
      id: id ?? this.id,
      screenMode: screenMode ?? this.screenMode,
      slideDuration: slideDuration ?? this.slideDuration,
      currentSlide: currentSlide ?? this.currentSlide,
      autoRotate: autoRotate ?? this.autoRotate,
      showTeamScores: showTeamScores ?? this.showTeamScores,
      showResults: showResults ?? this.showResults,
      showAnnouncements: showAnnouncements ?? this.showAnnouncements,
      customMessage: customMessage ?? this.customMessage,
      announcedProgramId: announcedProgramId ?? this.announcedProgramId,
      announcedResultNumber:
          announcedResultNumber ?? this.announcedResultNumber,
      revealedPositions: revealedPositions ?? this.revealedPositions,
    );
  }

  Map<String, dynamic> toMap() {
    final statePayload = {
      'announcedProgramId': announcedProgramId,
      'announcedResultNumber': announcedResultNumber,
      'revealedPositions': revealedPositions,
      'screenMode': screenMode,
      'slideDuration': slideDuration,
    };
    final serializedCustom = jsonEncode(statePayload);

    return {
      'id': id,
      'screenMode': screenMode,
      'slideDuration': slideDuration,
      'currentSlide': currentSlide,
      'autoRotate': autoRotate,
      'showTeamScores': showTeamScores,
      'showResults': showResults,
      'showAnnouncements': showAnnouncements,
      'customMessage': serializedCustom,
      'announcedProgramId': announcedProgramId,
      'announcedResultNumber': announcedResultNumber,
      'revealedPositions': revealedPositions,
    };
  }

  factory TvSettings.fromMap(Map<String, dynamic> map) {
    String? progId = map['announcedProgramId']?.toString();
    int? resNum = (map['announcedResultNumber'] as num?)?.toInt();
    List<int> positions = [];

    if (map['revealedPositions'] is List) {
      positions = (map['revealedPositions'] as List)
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((p) => p > 0)
          .toList();
    }

    final rawCustom = map['customMessage'] ?? map['activeAnnouncementId'];
    if (rawCustom is String && rawCustom.startsWith('{') && rawCustom.endsWith('}')) {
      try {
        final decoded = jsonDecode(rawCustom) as Map<String, dynamic>;
        progId = progId ?? decoded['announcedProgramId']?.toString();
        resNum = resNum ?? (decoded['announcedResultNumber'] as num?)?.toInt();
        if (positions.isEmpty && decoded['revealedPositions'] is List) {
          positions = (decoded['revealedPositions'] as List)
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .where((p) => p > 0)
              .toList();
        }
      } catch (_) {}
    }

    return TvSettings(
      id: map['id']?.toString() ?? 'default_tv_settings',
      screenMode: map['screenMode']?.toString() ?? 'ONLY_MAIN',
      slideDuration: (map['slideDuration'] as num?)?.toInt() ?? 15,
      currentSlide: (map['currentSlide'] as num?)?.toInt() ?? 0,
      autoRotate: map['autoRotate'] == null ? true : (map['autoRotate'] as bool),
      showTeamScores: map['showTeamScores'] == null ? true : (map['showTeamScores'] as bool),
      showResults: map['showResults'] == null ? true : (map['showResults'] as bool),
      showAnnouncements: map['showAnnouncements'] == null ? true : (map['showAnnouncements'] as bool),
      customMessage: rawCustom?.toString(),
      announcedProgramId: progId,
      announcedResultNumber: resNum,
      revealedPositions: positions,
    );
  }
}
