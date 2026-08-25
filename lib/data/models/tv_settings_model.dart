class TvSettings {
  final String id;
  final String screenMode; // AUTO, SCOREBOARD, RESULTS, ANNOUNCEMENT, CUSTOM
  final int slideDuration; // in seconds, default 15
  final int currentSlide;
  final bool autoRotate;
  final bool showTeamScores;
  final bool showResults;
  final bool showAnnouncements;
  final String? customMessage;

  TvSettings({
    this.id = 'default_tv_settings',
    this.screenMode = 'AUTO',
    this.slideDuration = 15,
    this.currentSlide = 0,
    this.autoRotate = true,
    this.showTeamScores = true,
    this.showResults = true,
    this.showAnnouncements = true,
    this.customMessage,
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'screenMode': screenMode,
      'slideDuration': slideDuration,
      'currentSlide': currentSlide,
      'autoRotate': autoRotate,
      'showTeamScores': showTeamScores,
      'showResults': showResults,
      'showAnnouncements': showAnnouncements,
      'customMessage': customMessage,
    };
  }

  factory TvSettings.fromMap(Map<String, dynamic> map) {
    return TvSettings(
      id: map['id'] ?? 'default_tv_settings',
      screenMode: map['screenMode'] ?? 'AUTO',
      slideDuration: map['slideDuration'] ?? 15,
      currentSlide: map['currentSlide'] ?? 0,
      autoRotate: map['autoRotate'] ?? true,
      showTeamScores: map['showTeamScores'] ?? true,
      showResults: map['showResults'] ?? true,
      showAnnouncements: map['showAnnouncements'] ?? true,
      customMessage: map['customMessage'],
    );
  }
}
