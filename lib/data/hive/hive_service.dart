import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String studentsBox = 'students';
  static const String teamsBox = 'teams';
  static const String leadersBox = 'leaders';
  static const String programsBox = 'programs';
  static const String registrationsBox = 'registrations';
  static const String resultsBox = 'results';
  static const String juriesBox = 'juries';
  static const String venuesBox = 'venues';
  static const String schedulesBox = 'schedules';
  static const String announcementsBox = 'announcements';
  static const String tvSettingsBox = 'tv_settings';
  static const String usersBox = 'users';
  static const String auditLogsBox = 'audit_logs';

  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    await Future.wait([
      Hive.openBox<Map>(studentsBox),
      Hive.openBox<Map>(teamsBox),
      Hive.openBox<Map>(leadersBox),
      Hive.openBox<Map>(programsBox),
      Hive.openBox<Map>(registrationsBox),
      Hive.openBox<Map>(resultsBox),
      Hive.openBox<Map>(juriesBox),
      Hive.openBox<Map>(venuesBox),
      Hive.openBox<Map>(schedulesBox),
      Hive.openBox<Map>(announcementsBox),
      Hive.openBox<Map>(tvSettingsBox),
      Hive.openBox<Map>(usersBox),
      Hive.openBox<Map>(auditLogsBox),
    ]);

    _isInitialized = true;
    if (kDebugMode) {
      print('Hive initialized with 13 boxes successfully.');
    }
  }

  static Box<Map> getBox(String name) {
    return Hive.box<Map>(name);
  }

  static Future<void> clearAllBoxes() async {
    final boxes = [
      studentsBox,
      teamsBox,
      leadersBox,
      programsBox,
      registrationsBox,
      resultsBox,
      juriesBox,
      venuesBox,
      schedulesBox,
      announcementsBox,
      tvSettingsBox,
      usersBox,
      auditLogsBox,
    ];

    for (final boxName in boxes) {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box<Map>(boxName).clear();
      }
    }
  }
}
