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
    this.slideDuration = 30,
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
      'announced_program_id': announcedProgramId,
      'announcedResultNumber': announcedResultNumber,
      'announced_result_number': announcedResultNumber,
      'revealedPositions': revealedPositions,
      'revealed_positions': revealedPositions,
      'screenMode': screenMode,
      'screen_mode': screenMode,
      'slideDuration': slideDuration,
      'slide_duration': slideDuration,
      'autoRotate': autoRotate,
      'auto_rotate': autoRotate,
    };
    final serializedCustom = jsonEncode(statePayload);

    return {
      'id': id,
      'screenMode': screenMode,
      'screen_mode': screenMode,
      'slideDuration': slideDuration,
      'slide_duration': slideDuration,
      'currentSlide': currentSlide,
      'current_slide': currentSlide,
      'autoRotate': autoRotate,
      'auto_rotate': autoRotate,
      'showTeamScores': showTeamScores,
      'show_team_scores': showTeamScores,
      'showResults': showResults,
      'show_results': showResults,
      'showAnnouncements': showAnnouncements,
      'show_announcements': showAnnouncements,
      'customMessage': serializedCustom,
      'custom_message': serializedCustom,
      'activeAnnouncementId': serializedCustom,
      'active_announcement_id': serializedCustom,
      'announcedProgramId': announcedProgramId,
      'announced_program_id': announcedProgramId,
      'announcedResultNumber': announcedResultNumber,
      'announced_result_number': announcedResultNumber,
      'revealedPositions': revealedPositions,
      'revealed_positions': revealedPositions,
    };
  }

  factory TvSettings.fromMap(Map<String, dynamic> map) {
    String? progId = (map['announcedProgramId'] ?? map['announced_program_id'])?.toString();
    int? resNum = (map['announcedResultNumber'] ?? map['announced_result_number'] as num?)?.toInt();
    List<int> positions = [];
    String? modeStr = (map['screenMode'] ?? map['screen_mode'])?.toString();
    int? slideDur = (map['slideDuration'] ?? map['slide_duration'] as num?)?.toInt();
    bool? autoRot;
    if (map['autoRotate'] != null) {
      autoRot = map['autoRotate'] as bool?;
    } else if (map['auto_rotate'] != null) {
      autoRot = map['auto_rotate'] as bool?;
    }

    if (map['revealedPositions'] is List) {
      positions = (map['revealedPositions'] as List)
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((p) => p > 0)
          .toList();
    } else if (map['revealed_positions'] is List) {
      positions = (map['revealed_positions'] as List)
          .map((e) => int.tryParse(e.toString()) ?? 0)
          .where((p) => p > 0)
          .toList();
    }

    final rawCustom = map['customMessage'] ?? map['custom_message'] ?? map['activeAnnouncementId'] ?? map['active_announcement_id'];
    if (rawCustom is String && rawCustom.startsWith('{') && rawCustom.endsWith('}')) {
      try {
        final decoded = jsonDecode(rawCustom) as Map<String, dynamic>;
        progId = progId ?? (decoded['announcedProgramId'] ?? decoded['announced_program_id'])?.toString();
        resNum = resNum ?? ((decoded['announcedResultNumber'] ?? decoded['announced_result_number']) as num?)?.toInt();
        if (decoded['screenMode'] != null || decoded['screen_mode'] != null) {
          modeStr = (decoded['screenMode'] ?? decoded['screen_mode'])?.toString();
        }
        if (decoded['slideDuration'] != null || decoded['slide_duration'] != null) {
          slideDur = ((decoded['slideDuration'] ?? decoded['slide_duration']) as num?)?.toInt();
        }
        if (decoded['autoRotate'] != null || decoded['auto_rotate'] != null) {
          autoRot = ((decoded['autoRotate'] ?? decoded['auto_rotate']) as bool?);
        }
        if (positions.isEmpty) {
          final decPos = decoded['revealedPositions'] ?? decoded['revealed_positions'];
          if (decPos is List) {
            positions = decPos
                .map((e) => int.tryParse(e.toString()) ?? 0)
                .where((p) => p > 0)
                .toList();
          }
        }
      } catch (_) {}
    }

    return TvSettings(
      id: map['id']?.toString() ?? 'default_tv_settings',
      screenMode: modeStr ?? 'ONLY_MAIN',
      slideDuration: slideDur ?? 30,
      currentSlide: (map['currentSlide'] ?? map['current_slide'] as num?)?.toInt() ?? 0,
      autoRotate: autoRot ?? true,
      showTeamScores: (map['showTeamScores'] ?? map['show_team_scores']) == null ? true : (map['showTeamScores'] ?? map['show_team_scores']) as bool,
      showResults: (map['showResults'] ?? map['show_results']) == null ? true : (map['showResults'] ?? map['show_results']) as bool,
      showAnnouncements: (map['showAnnouncements'] ?? map['show_announcements']) == null ? true : (map['showAnnouncements'] ?? map['show_announcements']) as bool,
      customMessage: rawCustom?.toString(),
      announcedProgramId: progId,
      announcedResultNumber: resNum,
      revealedPositions: positions,
    );
  }
}
