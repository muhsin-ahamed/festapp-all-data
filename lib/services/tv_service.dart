import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/models/tv_settings_model.dart';
import '../data/repositories/app_repositories.dart';

class TvService extends ChangeNotifier {
  final TvSettingsRepository tvSettingsRepository;
  Timer? _timer;
  TvSettings _settings = TvSettings();
  int _currentSlideIndex = 0; // 0: Scoreboard, 1: Latest Results

  TvService({required this.tvSettingsRepository}) {
    _loadSettings();
  }

  TvSettings get settings => _settings;
  int get currentSlideIndex => _currentSlideIndex;

  Future<void> _loadSettings() async {
    _settings = await tvSettingsRepository.getSettings();
    notifyListeners();
    _startTimerIfNeeded();
  }

  void _startTimerIfNeeded() {
    _timer?.cancel();
    if (_settings.autoRotate && _settings.screenMode == 'AUTO') {
      _timer = Timer.periodic(
        Duration(seconds: _settings.slideDuration),
        (_) => nextSlide(),
      );
    }
  }

  void nextSlide() {
    _currentSlideIndex = (_currentSlideIndex + 1) % 2;
    notifyListeners();
  }

  void previousSlide() {
    _currentSlideIndex = (_currentSlideIndex - 1 + 2) % 2;
    notifyListeners();
  }

  Future<void> updateSlideDuration(int seconds) async {
    _settings = _settings.copyWith(slideDuration: seconds);
    await tvSettingsRepository.updateSettings(_settings);
    _startTimerIfNeeded();
    notifyListeners();
  }

  Future<void> setAutoRotate(bool enabled) async {
    _settings = _settings.copyWith(autoRotate: enabled);
    await tvSettingsRepository.updateSettings(_settings);
    _startTimerIfNeeded();
    notifyListeners();
  }

  Future<void> setScreenMode(String mode) async {
    _settings = _settings.copyWith(screenMode: mode);
    await tvSettingsRepository.updateSettings(_settings);
    _startTimerIfNeeded();
    notifyListeners();
  }

  Future<void> setCustomMessage(String? msg) async {
    _settings = _settings.copyWith(customMessage: msg);
    await tvSettingsRepository.updateSettings(_settings);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
