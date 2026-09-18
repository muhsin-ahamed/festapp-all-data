import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/tv_settings_model.dart';
import '../data/repositories/app_repositories.dart';

class TvService extends ChangeNotifier {
  final TvSettingsRepository tvSettingsRepository;
  Timer? _timer;
  Timer? _syncTimer;
  TvSettings _settings = TvSettings();
  int _currentSlideIndex = 0;
  DateTime? _lastLocalUpdateTime;

  TvService({required this.tvSettingsRepository}) {
    _loadSettings();
    _startSyncTimer();
  }

  TvSettings get settings => _settings;
  int get currentSlideIndex => _currentSlideIndex;

  Future<void> _loadSettings() async {
    _settings = await tvSettingsRepository.getSettings();
    notifyListeners();
    _startTimerIfNeeded();
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        if (_lastLocalUpdateTime != null &&
            DateTime.now().difference(_lastLocalUpdateTime!).inSeconds < 3) {
          return;
        }
        final remote = await tvSettingsRepository.getSettings();
        if (_hasSettingsChanged(_settings, remote)) {
          _settings = remote;
          _startTimerIfNeeded();
          notifyListeners();
        }
      } catch (_) {}
    });
  }

  bool _hasSettingsChanged(TvSettings a, TvSettings b) {
    if (a.screenMode != b.screenMode) return true;
    if (a.slideDuration != b.slideDuration) return true;
    if (a.autoRotate != b.autoRotate) return true;
    if (a.announcedProgramId != b.announcedProgramId) return true;
    if (a.announcedResultNumber != b.announcedResultNumber) return true;
    if (a.revealedPositions.length != b.revealedPositions.length) return true;
    for (int i = 0; i < a.revealedPositions.length; i++) {
      if (a.revealedPositions[i] != b.revealedPositions[i]) return true;
    }
    return false;
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    final mode = _settings.screenMode;
    final isAuto = mode == 'AUTO_WITH_SCOREBOARD' ||
        mode == 'AUTO_WITHOUT_SCOREBOARD' ||
        mode == 'AUTO';

    if (_settings.autoRotate && isAuto) {
      _timer = Timer.periodic(
        Duration(seconds: _settings.slideDuration),
        (_) => nextSlide(),
      );
    }
  }

  void nextSlide() {
    int maxSlides = 3;
    if (_settings.screenMode == 'AUTO_WITHOUT_SCOREBOARD') {
      maxSlides = 2; // 0: Main Poster, 1: Results
    } else {
      maxSlides = 3; // 0: Main Poster, 1: Scoreboard, 2: Results
    }
    _currentSlideIndex = (_currentSlideIndex + 1) % maxSlides;
    notifyListeners();
  }

  void previousSlide() {
    int maxSlides = 3;
    if (_settings.screenMode == 'AUTO_WITHOUT_SCOREBOARD') {
      maxSlides = 2;
    } else {
      maxSlides = 3;
    }
    _currentSlideIndex = (_currentSlideIndex - 1 + maxSlides) % maxSlides;
    notifyListeners();
  }

  Future<void> updateSlideDuration(int seconds) async {
    _settings = _settings.copyWith(slideDuration: seconds);
    _lastLocalUpdateTime = DateTime.now();
    await tvSettingsRepository.updateSettings(_settings);
    _startTimerIfNeeded();
    notifyListeners();
  }

  Future<void> setAutoRotate(bool enabled) async {
    _settings = _settings.copyWith(autoRotate: enabled);
    _lastLocalUpdateTime = DateTime.now();
    await tvSettingsRepository.updateSettings(_settings);
    _startTimerIfNeeded();
    notifyListeners();
  }

  Future<void> setScreenMode(
    String mode, {
    int? slideDuration,
    bool? autoRotate,
  }) async {
    _currentSlideIndex = 0;
    _settings = _settings.copyWith(
      screenMode: mode,
      slideDuration: slideDuration ?? _settings.slideDuration,
      autoRotate: autoRotate ?? _settings.autoRotate,
    );
    _lastLocalUpdateTime = DateTime.now();
    notifyListeners();
    _startTimerIfNeeded();
    try {
      await tvSettingsRepository.updateSettings(_settings);
    } catch (_) {}
  }

  // --- RESULT ANNOUNCEMENT CONTROLLERS ---
  Future<void> startAnnouncement({
    required String programId,
    required int resultNumber,
  }) async {
    _settings = _settings.copyWith(
      screenMode: 'ANNOUNCE_RESULT',
      announcedProgramId: programId,
      announcedResultNumber: resultNumber,
      revealedPositions: [],
    );
    _lastLocalUpdateTime = DateTime.now();
    await tvSettingsRepository.updateSettings(_settings);
    _startTimerIfNeeded();
    notifyListeners();
  }

  Future<void> setAnnouncedResultNumber(int number) async {
    _settings = _settings.copyWith(announcedResultNumber: number);
    _lastLocalUpdateTime = DateTime.now();
    await tvSettingsRepository.updateSettings(_settings);
    notifyListeners();
  }

  Future<void> togglePositionReveal(int position) async {
    final list = List<int>.from(_settings.revealedPositions);
    if (list.contains(position)) {
      list.remove(position);
    } else {
      list.add(position);
    }
    _settings = _settings.copyWith(revealedPositions: list);
    _lastLocalUpdateTime = DateTime.now();
    await tvSettingsRepository.updateSettings(_settings);
    notifyListeners();
  }

  Future<void> revealPosition(int position) async {
    if (_settings.revealedPositions.contains(position)) return;
    final list = List<int>.from(_settings.revealedPositions)..add(position);
    _settings = _settings.copyWith(revealedPositions: list);
    _lastLocalUpdateTime = DateTime.now();
    await tvSettingsRepository.updateSettings(_settings);
    notifyListeners();
  }

  Future<void> hidePosition(int position) async {
    if (!_settings.revealedPositions.contains(position)) return;
    final list = List<int>.from(_settings.revealedPositions)..remove(position);
    _settings = _settings.copyWith(revealedPositions: list);
    _lastLocalUpdateTime = DateTime.now();
    await tvSettingsRepository.updateSettings(_settings);
    notifyListeners();
  }

  Future<void> revealAllPositions() async {
    _settings = _settings.copyWith(revealedPositions: [1, 2, 3]);
    _lastLocalUpdateTime = DateTime.now();
    await tvSettingsRepository.updateSettings(_settings);
    notifyListeners();
  }

  Future<void> hideAllPositions() async {
    _settings = _settings.copyWith(revealedPositions: []);
    _lastLocalUpdateTime = DateTime.now();
    await tvSettingsRepository.updateSettings(_settings);
    notifyListeners();
  }

  Future<void> setCustomMessage(String? msg) async {
    _settings = _settings.copyWith(customMessage: msg);
    _lastLocalUpdateTime = DateTime.now();
    await tvSettingsRepository.updateSettings(_settings);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }
}
