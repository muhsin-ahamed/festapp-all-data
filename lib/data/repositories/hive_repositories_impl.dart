import '../hive/hive_service.dart';
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
import '../../core/constants/app_constants.dart';
import 'app_repositories.dart';

class HiveStudentRepository implements StudentRepository {
  final box = HiveService.getBox(HiveService.studentsBox);

  @override
  Future<List<Student>> getStudents() async {
    return box.values
        .map((e) => Student.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<Student?> getById(String id) async {
    final raw = box.get(id);
    if (raw == null) return null;
    return Student.fromMap(Map<String, dynamic>.from(raw));
  }

  @override
  Future<Student?> getByChaseNumber(String chaseNumber) async {
    final students = await getStudents();
    try {
      return students.firstWhere(
        (s) => s.chaseNumber.trim().toLowerCase() == chaseNumber.trim().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Student>> getByTeam(String teamId) async {
    final students = await getStudents();
    return students.where((s) => s.teamId == teamId).toList();
  }

  @override
  Future<List<Student>> getBySection(FestSection section) async {
    final students = await getStudents();
    return students.where((s) => s.section == section).toList();
  }

  @override
  Future<void> addStudent(Student student) async {
    await box.put(student.id, student.toMap());
  }

  @override
  Future<void> updateStudent(Student student) async {
    await box.put(student.id, student.toMap());
  }

  @override
  Future<void> deleteStudent(String id) async {
    await box.delete(id);
  }
}

class HiveTeamRepository implements TeamRepository {
  final box = HiveService.getBox(HiveService.teamsBox);

  @override
  Future<List<Team>> getTeams() async {
    return box.values
        .map((e) => Team.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<Team?> getById(String id) async {
    final raw = box.get(id);
    if (raw == null) return null;
    return Team.fromMap(Map<String, dynamic>.from(raw));
  }

  @override
  Future<Team?> getByCode(String code) async {
    final teams = await getTeams();
    try {
      return teams.firstWhere(
        (t) => t.teamCode.trim().toLowerCase() == code.trim().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addTeam(Team team) async {
    await box.put(team.id, team.toMap());
  }

  @override
  Future<void> updateTeam(Team team) async {
    await box.put(team.id, team.toMap());
  }

  @override
  Future<void> deleteTeam(String id) async {
    await box.delete(id);
  }
}

class HiveTeamLeaderRepository implements TeamLeaderRepository {
  final box = HiveService.getBox(HiveService.leadersBox);

  @override
  Future<List<TeamLeader>> getLeaders() async {
    return box.values
        .map((e) => TeamLeader.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<TeamLeader?> getById(String id) async {
    final raw = box.get(id);
    if (raw == null) return null;
    return TeamLeader.fromMap(Map<String, dynamic>.from(raw));
  }

  @override
  Future<TeamLeader?> getByUsername(String username) async {
    final leaders = await getLeaders();
    try {
      return leaders.firstWhere(
        (l) => l.username.trim().toLowerCase() == username.trim().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<TeamLeader?> getByTeamId(String teamId) async {
    final leaders = await getLeaders();
    try {
      return leaders.firstWhere((l) => l.teamId == teamId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addLeader(TeamLeader leader) async {
    await box.put(leader.id, leader.toMap());
  }

  @override
  Future<void> updateLeader(TeamLeader leader) async {
    await box.put(leader.id, leader.toMap());
  }

  @override
  Future<void> deleteLeader(String id) async {
    await box.delete(id);
  }
}

class HiveProgramRepository implements ProgramRepository {
  final box = HiveService.getBox(HiveService.programsBox);

  @override
  Future<List<Program>> getPrograms() async {
    return box.values
        .map((e) => Program.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<Program?> getById(String id) async {
    final raw = box.get(id);
    if (raw == null) return null;
    return Program.fromMap(Map<String, dynamic>.from(raw));
  }

  @override
  Future<Program?> getByCode(String code) async {
    final programs = await getPrograms();
    try {
      return programs.firstWhere(
        (p) => p.programCode.trim().toLowerCase() == code.trim().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Program>> getBySection(FestSection section) async {
    final programs = await getPrograms();
    return programs.where((p) => p.section == section).toList();
  }

  @override
  Future<void> addProgram(Program program) async {
    await box.put(program.id, program.toMap());
  }

  @override
  Future<void> updateProgram(Program program) async {
    await box.put(program.id, program.toMap());
  }

  @override
  Future<void> deleteProgram(String id) async {
    await box.delete(id);
  }
}

class HiveRegistrationRepository implements RegistrationRepository {
  final box = HiveService.getBox(HiveService.registrationsBox);

  @override
  Future<List<Registration>> getRegistrations() async {
    return box.values
        .map((e) => Registration.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<Registration>> getByStudent(String studentId) async {
    final regs = await getRegistrations();
    return regs.where((r) => r.studentId == studentId).toList();
  }

  @override
  Future<List<Registration>> getByProgram(String programId) async {
    final regs = await getRegistrations();
    return regs.where((r) => r.programId == programId).toList();
  }

  @override
  Future<List<Registration>> getByTeam(String teamId) async {
    final regs = await getRegistrations();
    return regs.where((r) => r.teamId == teamId).toList();
  }

  @override
  Future<Registration?> getByStudentAndProgram(String studentId, String programId) async {
    final regs = await getRegistrations();
    try {
      return regs.firstWhere(
        (r) => r.studentId == studentId && r.programId == programId,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addRegistration(Registration reg) async {
    await box.put(reg.id, reg.toMap());
  }

  @override
  Future<void> updateRegistration(Registration reg) async {
    await box.put(reg.id, reg.toMap());
  }

  @override
  Future<void> deleteRegistration(String id) async {
    await box.delete(id);
  }
}

class HiveResultRepository implements ResultRepository {
  final box = HiveService.getBox(HiveService.resultsBox);

  @override
  Future<List<Result>> getResults() async {
    return box.values
        .map((e) => Result.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<Result>> getPublishedResults() async {
    final results = await getResults();
    return results.where((r) => r.status == ResultStatus.published || r.status == ResultStatus.announced).toList();
  }

  @override
  Future<List<Result>> getByProgram(String programId) async {
    final results = await getResults();
    return results.where((r) => r.programId == programId).toList();
  }

  @override
  Future<List<Result>> getByStudent(String studentId) async {
    final results = await getResults();
    return results.where((r) => r.studentId == studentId).toList();
  }

  @override
  Future<List<Result>> getByTeam(String teamId) async {
    final results = await getResults();
    return results.where((r) => r.teamId == teamId).toList();
  }

  @override
  Future<Result?> getById(String id) async {
    final raw = box.get(id);
    if (raw == null) return null;
    return Result.fromMap(Map<String, dynamic>.from(raw));
  }

  @override
  Future<void> saveResult(Result result) async {
    await box.put(result.id, result.toMap());
  }

  @override
  Future<void> updateResult(Result result) async {
    await box.put(result.id, result.toMap());
  }

  @override
  Future<void> deleteResult(String id) async {
    await box.delete(id);
  }
}

class HiveVenueRepository implements VenueRepository {
  final box = HiveService.getBox(HiveService.venuesBox);

  @override
  Future<List<Venue>> getVenues() async {
    return box.values
        .map((e) => Venue.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<Venue?> getById(String id) async {
    final raw = box.get(id);
    if (raw == null) return null;
    return Venue.fromMap(Map<String, dynamic>.from(raw));
  }

  @override
  Future<void> addVenue(Venue venue) async {
    await box.put(venue.id, venue.toMap());
  }

  @override
  Future<void> updateVenue(Venue venue) async {
    await box.put(venue.id, venue.toMap());
  }

  @override
  Future<void> deleteVenue(String id) async {
    await box.delete(id);
  }
}

class HiveScheduleRepository implements ScheduleRepository {
  final box = HiveService.getBox(HiveService.schedulesBox);

  @override
  Future<List<Schedule>> getSchedules() async {
    return box.values
        .map((e) => Schedule.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<Schedule?> getById(String id) async {
    final raw = box.get(id);
    if (raw == null) return null;
    return Schedule.fromMap(Map<String, dynamic>.from(raw));
  }

  @override
  Future<List<Schedule>> getByVenue(String venueId) async {
    final schedules = await getSchedules();
    return schedules.where((s) => s.venueId == venueId).toList();
  }

  @override
  Future<void> addSchedule(Schedule schedule) async {
    await box.put(schedule.id, schedule.toMap());
  }

  @override
  Future<void> updateSchedule(Schedule schedule) async {
    await box.put(schedule.id, schedule.toMap());
  }

  @override
  Future<void> deleteSchedule(String id) async {
    await box.delete(id);
  }
}

class HiveJuryRepository implements JuryRepository {
  final box = HiveService.getBox(HiveService.juriesBox);

  @override
  Future<List<Jury>> getJuries() async {
    return box.values
        .map((e) => Jury.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<Jury?> getById(String id) async {
    final raw = box.get(id);
    if (raw == null) return null;
    return Jury.fromMap(Map<String, dynamic>.from(raw));
  }

  @override
  Future<Jury?> getByUsername(String username) async {
    final juries = await getJuries();
    try {
      return juries.firstWhere(
        (j) => j.username.trim().toLowerCase() == username.trim().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addJury(Jury jury) async {
    await box.put(jury.id, jury.toMap());
  }

  @override
  Future<void> updateJury(Jury jury) async {
    await box.put(jury.id, jury.toMap());
  }

  @override
  Future<void> deleteJury(String id) async {
    await box.delete(id);
  }
}

class HiveAnnouncementRepository implements AnnouncementRepository {
  final box = HiveService.getBox(HiveService.announcementsBox);

  @override
  Future<List<Announcement>> getAnnouncements() async {
    return box.values
        .map((e) => Announcement.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<void> addAnnouncement(Announcement ann) async {
    await box.put(ann.id, ann.toMap());
  }

  @override
  Future<void> updateAnnouncement(Announcement ann) async {
    await box.put(ann.id, ann.toMap());
  }
}

class HiveTvSettingsRepository implements TvSettingsRepository {
  final box = HiveService.getBox(HiveService.tvSettingsBox);

  @override
  Future<TvSettings> getSettings() async {
    final raw = box.get('default_tv_settings');
    if (raw == null) return TvSettings();
    return TvSettings.fromMap(Map<String, dynamic>.from(raw));
  }

  @override
  Future<void> updateSettings(TvSettings settings) async {
    await box.put('default_tv_settings', settings.toMap());
  }
}

class HiveUserRepository implements UserRepository {
  final box = HiveService.getBox(HiveService.usersBox);

  @override
  Future<List<User>> getUsers() async {
    return box.values
        .map((e) => User.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<User?> getByUsername(String username) async {
    final users = await getUsers();
    try {
      return users.firstWhere(
        (u) => u.username.trim().toLowerCase() == username.trim().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveUser(User user) async {
    await box.put(user.id, user.toMap());
  }

  @override
  Future<void> deleteUser(String id) async {
    await box.delete(id);
  }
}

class HiveAuditLogRepository implements AuditLogRepository {
  final box = HiveService.getBox(HiveService.auditLogsBox);

  @override
  Future<List<AuditLog>> getLogs() async {
    final logs = box.values
        .map((e) => AuditLog.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  @override
  Future<void> addLog(AuditLog log) async {
    await box.put(log.id, log.toMap());
  }
}
