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

abstract class StudentRepository {
  Future<List<Student>> getStudents();
  Future<Student?> getById(String id);
  Future<Student?> getByChaseNumber(String chaseNumber);
  Future<List<Student>> getByTeam(String teamId);
  Future<List<Student>> getBySection(FestSection section);
  Future<void> addStudent(Student student);
  Future<void> addStudents(List<Student> students);
  Future<void> updateStudent(Student student);
  Future<void> deleteStudent(String id);
}

abstract class TeamRepository {
  Future<List<Team>> getTeams();
  Future<Team?> getById(String id);
  Future<Team?> getByCode(String code);
  Future<void> addTeam(Team team);
  Future<void> addTeams(List<Team> teams);
  Future<void> updateTeam(Team team);
  Future<void> deleteTeam(String id);
}

abstract class TeamLeaderRepository {
  Future<List<TeamLeader>> getLeaders();
  Future<TeamLeader?> getById(String id);
  Future<TeamLeader?> getByUsername(String username);
  Future<TeamLeader?> getByTeamId(String teamId);
  Future<void> addLeader(TeamLeader leader);
  Future<void> updateLeader(TeamLeader leader);
  Future<void> deleteLeader(String id);
}

abstract class ProgramRepository {
  Future<List<Program>> getPrograms();
  Future<Program?> getById(String id);
  Future<Program?> getByCode(String code);
  Future<List<Program>> getBySection(FestSection section);
  Future<void> addProgram(Program program);
  Future<void> addPrograms(List<Program> programs);
  Future<void> updateProgram(Program program);
  Future<void> deleteProgram(String id);
}

abstract class RegistrationRepository {
  Future<List<Registration>> getRegistrations();
  Future<List<Registration>> getByStudent(String studentId);
  Future<List<Registration>> getByProgram(String programId);
  Future<List<Registration>> getByTeam(String teamId);
  Future<Registration?> getByStudentAndProgram(String studentId, String programId);
  Future<void> addRegistration(Registration reg);
  Future<void> updateRegistration(Registration reg);
  Future<void> deleteRegistration(String id);
}

abstract class ResultRepository {
  Future<List<Result>> getResults();
  Future<List<Result>> getPublishedResults();
  Future<List<Result>> getByProgram(String programId);
  Future<List<Result>> getByStudent(String studentId);
  Future<List<Result>> getByTeam(String teamId);
  Future<Result?> getById(String id);
  Future<void> saveResult(Result result);
  Future<void> updateResult(Result result);
  Future<void> deleteResult(String id);
}

abstract class VenueRepository {
  Future<List<Venue>> getVenues();
  Future<Venue?> getById(String id);
  Future<void> addVenue(Venue venue);
  Future<void> addVenues(List<Venue> venues);
  Future<void> updateVenue(Venue venue);
  Future<void> deleteVenue(String id);
  Future<void> clearVenues();
}

abstract class ScheduleRepository {
  Future<List<Schedule>> getSchedules();
  Future<Schedule?> getById(String id);
  Future<List<Schedule>> getByVenue(String venueId);
  Future<void> addSchedule(Schedule schedule);
  Future<void> addSchedules(List<Schedule> schedules);
  Future<void> updateSchedule(Schedule schedule);
  Future<void> deleteSchedule(String id);
  Future<void> clearSchedules();
}

abstract class JuryRepository {
  Future<List<Jury>> getJuries();
  Future<Jury?> getById(String id);
  Future<Jury?> getByUsername(String username);
  Future<void> addJury(Jury jury);
  Future<void> updateJury(Jury jury);
  Future<void> deleteJury(String id);
}

abstract class AnnouncementRepository {
  Future<List<Announcement>> getAnnouncements();
  Future<void> addAnnouncement(Announcement ann);
  Future<void> updateAnnouncement(Announcement ann);
}

abstract class TvSettingsRepository {
  Future<TvSettings> getSettings();
  Future<void> updateSettings(TvSettings settings);
}

abstract class UserRepository {
  Future<List<User>> getUsers();
  Future<User?> getByUsername(String username);
  Future<void> saveUser(User user);
  Future<void> deleteUser(String id);
}

abstract class AuditLogRepository {
  Future<List<AuditLog>> getLogs();
  Future<void> addLog(AuditLog log);
}
