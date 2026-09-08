import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../../core/constants/app_constants.dart';
import '../models/student_model.dart';
import '../models/team_model.dart';
import '../models/team_leader_model.dart';
import '../models/program_model.dart';
import '../models/registration_model.dart';
import '../models/result_model.dart';
import '../models/venue_model.dart';
import '../models/schedule_model.dart';
import '../models/jury_model.dart';
import '../models/announcement_model.dart';
import '../models/tv_settings_model.dart';
import '../models/user_model.dart';
import '../models/audit_log_model.dart';
import 'app_repositories.dart';

class SupabaseHelper {
  static SupabaseClient get client => Supabase.instance.client;
}

SupabaseClient get _client => SupabaseHelper.client;

Future<dynamic> _safeInsert(String table, Map<String, dynamic> data) async {
  return await _client.from(table).insert(data).select();
}

Future<void> _safeInsertBatch(
  String table,
  List<Map<String, dynamic>> dataList,
) async {
  if (dataList.isEmpty) return;
  await _client.from(table).insert(dataList);
}

Future<dynamic> _safeUpdate(
  String table,
  Map<String, dynamic> data,
  String id,
) async {
  return await _client.from(table).update(data).eq('id', id).select();
}

Future<dynamic> _safeUpsert(String table, Map<String, dynamic> data) async {
  return await _client.from(table).upsert(data, onConflict: 'id').select();
}

class SupabaseStudentRepository implements StudentRepository {
  final String _table = 'students';

  @override
  Future<List<Student>> getStudents() async {
    final res = await _client.from(_table).select();
    return (res as List)
        .map((e) => Student.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Student?> getById(String id) async {
    final res = await _client.from(_table).select().eq('id', id).maybeSingle();
    return res != null ? Student.fromMap(res) : null;
  }

  @override
  Future<Student?> getByChaseNumber(String chaseNumber) async {
    final res = await _client
        .from(_table)
        .select()
        .or('chaseNumber.eq.$chaseNumber,chase_number.eq.$chaseNumber')
        .maybeSingle();
    return res != null ? Student.fromMap(res) : null;
  }

  @override
  Future<List<Student>> getByTeam(String teamId) async {
    final res = await _client
        .from(_table)
        .select()
        .or('teamId.eq.$teamId,team_id.eq.$teamId');
    return (res as List)
        .map((e) => Student.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Student>> getBySection(FestSection section) async {
    final res = await _client.from(_table).select().eq('section', section.name);
    return (res as List)
        .map((e) => Student.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> addStudent(Student student) async {
    await _safeInsert(_table, student.toMap());
  }

  @override
  Future<void> addStudents(List<Student> students) async {
    if (students.isEmpty) return;
    final maps = students.map((s) => s.toMap()).toList();
    await _safeInsertBatch(_table, maps);
  }

  @override
  Future<void> updateStudent(Student student) async {
    await _safeUpdate(_table, student.toMap(), student.id);
  }

  @override
  Future<void> deleteStudent(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}

class SupabaseTeamRepository implements TeamRepository {
  final String _table = 'teams';

  @override
  Future<List<Team>> getTeams() async {
    final res = await _client.from(_table).select();
    return (res as List)
        .map((e) => Team.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Team?> getById(String id) async {
    final res = await _client.from(_table).select().eq('id', id).maybeSingle();
    return res != null ? Team.fromMap(res) : null;
  }

  @override
  Future<Team?> getByCode(String code) async {
    final res = await _client
        .from(_table)
        .select()
        .or('teamCode.eq.$code,team_code.eq.$code')
        .maybeSingle();
    return res != null ? Team.fromMap(res) : null;
  }

  @override
  Future<void> addTeam(Team team) async {
    await _safeInsert(_table, team.toMap());
  }

  @override
  Future<void> addTeams(List<Team> teams) async {
    if (teams.isEmpty) return;
    final maps = teams.map((t) => t.toMap()).toList();
    await _safeInsertBatch(_table, maps);
  }

  @override
  Future<void> updateTeam(Team team) async {
    await _safeUpdate(_table, team.toMap(), team.id);
  }

  @override
  Future<void> deleteTeam(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}

class SupabaseTeamLeaderRepository implements TeamLeaderRepository {
  final String _table = 'team_leaders';

  @override
  Future<List<TeamLeader>> getLeaders() async {
    final res = await _client.from(_table).select();
    return (res as List)
        .map((e) => TeamLeader.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TeamLeader?> getById(String id) async {
    final res = await _client.from(_table).select().eq('id', id).maybeSingle();
    return res != null ? TeamLeader.fromMap(res) : null;
  }

  @override
  Future<TeamLeader?> getByUsername(String username) async {
    final res = await _client
        .from(_table)
        .select()
        .eq('username', username)
        .maybeSingle();
    return res != null ? TeamLeader.fromMap(res) : null;
  }

  @override
  Future<TeamLeader?> getByTeamId(String teamId) async {
    final res = await _client
        .from(_table)
        .select()
        .eq('teamId', teamId)
        .maybeSingle();
    return res != null ? TeamLeader.fromMap(res) : null;
  }

  @override
  Future<void> addLeader(TeamLeader leader) async {
    await _safeInsert(_table, leader.toMap());
  }

  @override
  Future<void> updateLeader(TeamLeader leader) async {
    await _safeUpdate(_table, leader.toMap(), leader.id);
  }

  @override
  Future<void> deleteLeader(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}

class SupabaseProgramRepository implements ProgramRepository {
  final String _table = 'programs';

  @override
  Future<List<Program>> getPrograms() async {
    final res = await _client.from(_table).select();
    return (res as List)
        .map((e) => Program.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Program?> getById(String id) async {
    final res = await _client.from(_table).select().eq('id', id).maybeSingle();
    return res != null ? Program.fromMap(res) : null;
  }

  @override
  Future<Program?> getByCode(String code) async {
    final res = await _client
        .from(_table)
        .select()
        .or('programCode.eq.$code,program_code.eq.$code')
        .maybeSingle();
    return res != null ? Program.fromMap(res) : null;
  }

  @override
  Future<List<Program>> getBySection(FestSection section) async {
    final res = await _client.from(_table).select().eq('section', section.name);
    return (res as List)
        .map((e) => Program.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> addProgram(Program program) async {
    await _safeInsert(_table, program.toMap());
  }

  @override
  Future<void> addPrograms(List<Program> programs) async {
    if (programs.isEmpty) return;
    final maps = programs.map((p) => p.toMap()).toList();
    await _safeInsertBatch(_table, maps);
  }

  @override
  Future<void> updateProgram(Program program) async {
    await _safeUpdate(_table, program.toMap(), program.id);
  }

  @override
  Future<void> deleteProgram(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}

class SupabaseRegistrationRepository implements RegistrationRepository {
  final String _table = 'registrations';

  @override
  Future<List<Registration>> getRegistrations() async {
    final res = await _client.from(_table).select();
    return (res as List)
        .map((e) => Registration.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Registration>> getByStudent(String studentId) async {
    final res = await _client.from(_table).select().eq('studentId', studentId);
    return (res as List)
        .map((e) => Registration.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Registration>> getByProgram(String programId) async {
    final res = await _client.from(_table).select().eq('programId', programId);
    return (res as List)
        .map((e) => Registration.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Registration>> getByTeam(String teamId) async {
    final res = await _client.from(_table).select().eq('teamId', teamId);
    return (res as List)
        .map((e) => Registration.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Registration?> getByStudentAndProgram(
    String studentId,
    String programId,
  ) async {
    final res = await _client
        .from(_table)
        .select()
        .eq('studentId', studentId)
        .eq('programId', programId)
        .maybeSingle();
    return res != null ? Registration.fromMap(res) : null;
  }

  @override
  Future<void> addRegistration(Registration reg) async {
    await _safeInsert(_table, reg.toMap());
  }

  @override
  Future<void> updateRegistration(Registration reg) async {
    await _safeUpdate(_table, reg.toMap(), reg.id);
  }

  @override
  Future<void> deleteRegistration(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}

class SupabaseResultRepository implements ResultRepository {
  final String _table = 'results';

  @override
  Future<List<Result>> getResults() async {
    final res = await _client.from(_table).select();
    return (res as List)
        .map((e) => Result.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Result>> getPublishedResults() async {
    final res = await _client
        .from(_table)
        .select()
        .eq('status', ResultStatus.published.name);
    return (res as List)
        .map((e) => Result.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Result>> getByProgram(String programId) async {
    final res = await _client.from(_table).select().eq('programId', programId);
    return (res as List)
        .map((e) => Result.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Result>> getByStudent(String studentId) async {
    final res = await _client.from(_table).select().eq('studentId', studentId);
    return (res as List)
        .map((e) => Result.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Result>> getByTeam(String teamId) async {
    final res = await _client.from(_table).select().eq('teamId', teamId);
    return (res as List)
        .map((e) => Result.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Result?> getById(String id) async {
    final res = await _client.from(_table).select().eq('id', id).maybeSingle();
    return res != null ? Result.fromMap(res) : null;
  }

  @override
  Future<void> saveResult(Result result) async {
    await _safeUpsert(_table, result.toMap());
  }

  @override
  Future<void> updateResult(Result result) async {
    await _safeUpdate(_table, result.toMap(), result.id);
  }

  @override
  Future<void> deleteResult(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}

class SupabaseVenueRepository implements VenueRepository {
  final String _table = 'venues';
  static final List<Venue> _localVenues = [];

  @override
  Future<List<Venue>> getVenues() async {
    try {
      final res = await _client.from(_table).select();
      final items = (res as List)
          .map((e) => Venue.fromMap(e as Map<String, dynamic>))
          .toList();
      if (items.isNotEmpty) {
        final remoteIds = items.map((v) => v.id).toSet();
        for (final v in _localVenues) {
          if (!remoteIds.contains(v.id)) {
            items.add(v);
          }
        }
        return items;
      }
    } catch (_) {}
    return List.from(_localVenues);
  }

  @override
  Future<Venue?> getById(String id) async {
    try {
      final res = await _client
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle();
      if (res != null) return Venue.fromMap(res);
    } catch (_) {}
    try {
      return _localVenues.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addVenue(Venue venue) async {
    try {
      await _safeUpsert(_table, venue.toMap());
    } catch (_) {
      try {
        await _safeInsert(_table, venue.toMap());
      } catch (_) {}
    }
    _localVenues.removeWhere((v) => v.id == venue.id);
    _localVenues.add(venue);
  }

  @override
  Future<void> addVenues(List<Venue> venues) async {
    for (final v in venues) {
      await addVenue(v);
    }
  }

  @override
  Future<void> updateVenue(Venue venue) async {
    try {
      await _safeUpdate(_table, venue.toMap(), venue.id);
    } catch (_) {}
    final idx = _localVenues.indexWhere((v) => v.id == venue.id);
    if (idx != -1) {
      _localVenues[idx] = venue;
    } else {
      _localVenues.add(venue);
    }
  }

  @override
  Future<void> deleteVenue(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (_) {}
    _localVenues.removeWhere((v) => v.id == id);
  }

  @override
  Future<void> clearVenues() async {
    try {
      await _client.from(_table).delete().neq('id', '');
    } catch (_) {}
    _localVenues.clear();
  }
}

class SupabaseScheduleRepository implements ScheduleRepository {
  final String _table = 'schedules';
  static final List<Schedule> _localSchedules = [];

  @override
  Future<List<Schedule>> getSchedules() async {
    try {
      final res = await _client.from(_table).select();
      final items = (res as List)
          .map((e) => Schedule.fromMap(e as Map<String, dynamic>))
          .toList();
      if (items.isNotEmpty) {
        final remoteIds = items.map((s) => s.id).toSet();
        for (final s in _localSchedules) {
          if (!remoteIds.contains(s.id)) {
            items.add(s);
          }
        }
        return items;
      }
    } catch (_) {}
    return List.from(_localSchedules);
  }

  @override
  Future<Schedule?> getById(String id) async {
    try {
      final res = await _client
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle();
      if (res != null) return Schedule.fromMap(res);
    } catch (_) {}
    try {
      return _localSchedules.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Schedule>> getByVenue(String venueId) async {
    try {
      final res = await _client.from(_table).select().eq('venueId', venueId);
      final items = (res as List)
          .map((e) => Schedule.fromMap(e as Map<String, dynamic>))
          .toList();
      if (items.isNotEmpty) return items;
    } catch (_) {}
    return _localSchedules.where((s) => s.venueId == venueId).toList();
  }

  @override
  Future<void> addSchedule(Schedule schedule) async {
    try {
      await _safeUpsert(_table, schedule.toMap());
    } catch (_) {
      try {
        await _safeInsert(_table, schedule.toMap());
      } catch (_) {}
    }
    _localSchedules.removeWhere((s) => s.id == schedule.id);
    _localSchedules.add(schedule);
  }

  @override
  Future<void> addSchedules(List<Schedule> schedules) async {
    for (final s in schedules) {
      await addSchedule(s);
    }
  }

  @override
  Future<void> updateSchedule(Schedule schedule) async {
    try {
      await _safeUpdate(_table, schedule.toMap(), schedule.id);
    } catch (_) {}
    final idx = _localSchedules.indexWhere((s) => s.id == schedule.id);
    if (idx != -1) {
      _localSchedules[idx] = schedule;
    } else {
      _localSchedules.add(schedule);
    }
  }

  @override
  Future<void> deleteSchedule(String id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (_) {}
    _localSchedules.removeWhere((s) => s.id == id);
  }

  @override
  Future<void> clearSchedules() async {
    try {
      await _client.from(_table).delete().neq('id', '');
    } catch (_) {}
    _localSchedules.clear();
  }
}

class SupabaseJuryRepository implements JuryRepository {
  final String _table = 'juries';

  @override
  Future<List<Jury>> getJuries() async {
    final res = await _client.from(_table).select();
    return (res as List)
        .map((e) => Jury.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Jury?> getById(String id) async {
    final res = await _client.from(_table).select().eq('id', id).maybeSingle();
    return res != null ? Jury.fromMap(res) : null;
  }

  @override
  Future<Jury?> getByUsername(String username) async {
    final res = await _client
        .from(_table)
        .select()
        .eq('username', username)
        .maybeSingle();
    return res != null ? Jury.fromMap(res) : null;
  }

  @override
  Future<void> addJury(Jury jury) async {
    await _safeInsert(_table, jury.toMap());
  }

  @override
  Future<void> updateJury(Jury jury) async {
    await _safeUpdate(_table, jury.toMap(), jury.id);
  }

  @override
  Future<void> deleteJury(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}

class SupabaseAnnouncementRepository implements AnnouncementRepository {
  final String _table = 'announcements';

  @override
  Future<List<Announcement>> getAnnouncements() async {
    final res = await _client.from(_table).select();
    return (res as List)
        .map((e) => Announcement.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> addAnnouncement(Announcement ann) async {
    await _safeInsert(_table, ann.toMap());
  }

  @override
  Future<void> updateAnnouncement(Announcement ann) async {
    await _safeUpdate(_table, ann.toMap(), ann.id);
  }
}

class SupabaseTvSettingsRepository implements TvSettingsRepository {
  final String _table = 'tv_settings';

  @override
  Future<TvSettings> getSettings() async {
    final res = await _client.from(_table).select().maybeSingle();
    if (res != null) {
      return TvSettings.fromMap(res);
    }
    final defaultSettings = TvSettings();
    await updateSettings(defaultSettings);
    return defaultSettings;
  }

  @override
  Future<void> updateSettings(TvSettings settings) async {
    await _safeUpsert(_table, settings.toMap());
  }
}

class SupabaseUserRepository implements UserRepository {
  final String _table = 'users';

  @override
  Future<List<User>> getUsers() async {
    final res = await _client.from(_table).select();
    return (res as List)
        .map((e) => User.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<User?> getByUsername(String username) async {
    final clean = username.trim();
    final res = await _client
        .from(_table)
        .select()
        .ilike('username', clean)
        .maybeSingle();
    return res != null ? User.fromMap(res) : null;
  }

  @override
  Future<void> saveUser(User user) async {
    await _safeUpsert(_table, user.toMap());
  }

  @override
  Future<void> deleteUser(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}

class SupabaseAuditLogRepository implements AuditLogRepository {
  final String _table = 'audit_logs';

  @override
  Future<List<AuditLog>> getLogs() async {
    final res = await _client.from(_table).select();
    return (res as List)
        .map((e) => AuditLog.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> addLog(AuditLog log) async {
    await _safeInsert(_table, log.toMap());
  }
}
