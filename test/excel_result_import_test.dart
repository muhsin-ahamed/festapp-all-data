import 'package:flutter_test/flutter_test.dart';
import 'package:excel/excel.dart';
import 'package:amia_fest/services/excel_service.dart';
import 'package:amia_fest/data/models/student_model.dart';
import 'package:amia_fest/data/models/team_model.dart';
import 'package:amia_fest/data/models/program_model.dart';
import 'package:amia_fest/data/models/result_model.dart';
import 'package:amia_fest/data/models/venue_model.dart';
import 'package:amia_fest/data/models/schedule_model.dart';
import 'package:amia_fest/data/models/registration_model.dart';
import 'package:amia_fest/core/constants/app_constants.dart';
import 'package:amia_fest/data/repositories/app_repositories.dart';

class FakeStudentRepository implements StudentRepository {
  final List<Student> students = [];
  @override
  Future<List<Student>> getStudents() async => List.from(students);
  @override
  Future<Student?> getById(String id) async =>
      students.where((s) => s.id == id).firstOrNull;
  @override
  Future<Student?> getByChaseNumber(String chaseNumber) async =>
      students.where((s) => s.chaseNumber == chaseNumber).firstOrNull;
  @override
  Future<List<Student>> getByTeam(String teamId) async =>
      students.where((s) => s.teamId == teamId).toList();
  @override
  Future<List<Student>> getBySection(FestSection section) async =>
      students.where((s) => s.section == section).toList();
  @override
  Future<void> addStudent(Student student) async => students.add(student);
  @override
  Future<void> addStudents(List<Student> newStudents) async =>
      students.addAll(newStudents);
  @override
  Future<void> updateStudent(Student student) async {
    final idx = students.indexWhere((s) => s.id == student.id);
    if (idx != -1) students[idx] = student;
  }
  @override
  Future<void> deleteStudent(String id) async =>
      students.removeWhere((s) => s.id == id);
}

class FakeTeamRepository implements TeamRepository {
  final List<Team> teams = [];
  @override
  Future<List<Team>> getTeams() async => List.from(teams);
  @override
  Future<Team?> getById(String id) async =>
      teams.where((t) => t.id == id).firstOrNull;
  @override
  Future<Team?> getByCode(String code) async =>
      teams.where((t) => t.teamCode == code).firstOrNull;
  @override
  Future<void> addTeam(Team team) async => teams.add(team);
  @override
  Future<void> addTeams(List<Team> newTeams) async => teams.addAll(newTeams);
  @override
  Future<void> updateTeam(Team team) async {
    final idx = teams.indexWhere((t) => t.id == team.id);
    if (idx != -1) teams[idx] = team;
  }
  @override
  Future<void> deleteTeam(String id) async =>
      teams.removeWhere((t) => t.id == id);
}

class FakeProgramRepository implements ProgramRepository {
  final List<Program> programs = [];
  @override
  Future<List<Program>> getPrograms() async => List.from(programs);
  @override
  Future<Program?> getById(String id) async =>
      programs.where((p) => p.id == id).firstOrNull;
  @override
  Future<Program?> getByCode(String code) async =>
      programs.where((p) => p.programCode == code).firstOrNull;
  @override
  Future<List<Program>> getBySection(FestSection section) async =>
      programs.where((p) => p.section == section).toList();
  @override
  Future<void> addProgram(Program program) async => programs.add(program);
  @override
  Future<void> addPrograms(List<Program> newPrograms) async =>
      programs.addAll(newPrograms);
  @override
  Future<void> updateProgram(Program program) async {
    final idx = programs.indexWhere((p) => p.id == program.id);
    if (idx != -1) programs[idx] = program;
  }
  @override
  Future<void> deleteProgram(String id) async =>
      programs.removeWhere((p) => p.id == id);
}

class FakeRegistrationRepository implements RegistrationRepository {
  final List<Registration> registrations = [];
  @override
  Future<List<Registration>> getRegistrations() async => registrations;
  @override
  Future<List<Registration>> getByProgram(String programId) async =>
      registrations.where((r) => r.programId == programId).toList();
  @override
  Future<List<Registration>> getByStudent(String studentId) async =>
      registrations.where((r) => r.studentId == studentId).toList();
  @override
  Future<List<Registration>> getByTeam(String teamId) async =>
      registrations.where((r) => r.teamId == teamId).toList();
  Future<Registration?> getById(String id) async =>
      registrations.where((r) => r.id == id).firstOrNull;
  @override
  Future<Registration?> getByStudentAndProgram(
          String studentId, String programId) async =>
      registrations
          .where((r) => r.studentId == studentId && r.programId == programId)
          .firstOrNull;
  @override
  Future<void> addRegistration(Registration reg) async => registrations.add(reg);
  @override
  Future<void> updateRegistration(Registration reg) async {
    final idx = registrations.indexWhere((r) => r.id == reg.id);
    if (idx != -1) registrations[idx] = reg;
  }
  @override
  Future<void> deleteRegistration(String id) async =>
      registrations.removeWhere((r) => r.id == id);
}

class FakeResultRepository implements ResultRepository {
  final List<Result> results = [];
  @override
  Future<List<Result>> getResults() async => results;
  @override
  Future<List<Result>> getPublishedResults() async =>
      results.where((r) => r.status == ResultStatus.published).toList();
  @override
  Future<List<Result>> getByProgram(String programId) async =>
      results.where((r) => r.programId == programId).toList();
  @override
  Future<List<Result>> getByStudent(String studentId) async =>
      results.where((r) => r.studentId == studentId).toList();
  @override
  Future<List<Result>> getByTeam(String teamId) async =>
      results.where((r) => r.teamId == teamId).toList();
  @override
  Future<Result?> getById(String id) async =>
      results.where((r) => r.id == id).firstOrNull;
  @override
  Future<void> saveResult(Result result) async {
    final idx = results.indexWhere((r) => r.id == result.id);
    if (idx != -1) {
      results[idx] = result;
    } else {
      results.add(result);
    }
  }
  @override
  Future<void> updateResult(Result result) async {
    final idx = results.indexWhere((r) => r.id == result.id);
    if (idx != -1) results[idx] = result;
  }
  @override
  Future<void> deleteResult(String id) async =>
      results.removeWhere((r) => r.id == id);
}

class FakeVenueRepository implements VenueRepository {
  @override
  Future<List<Venue>> getVenues() async => [];
  @override
  Future<Venue?> getById(String id) async => null;
  @override
  Future<void> addVenue(Venue venue) async {}
  @override
  Future<void> addVenues(List<Venue> venues) async {}
  @override
  Future<void> updateVenue(Venue venue) async {}
  @override
  Future<void> deleteVenue(String id) async {}
  @override
  Future<void> clearVenues() async {}
}

class FakeScheduleRepository implements ScheduleRepository {
  @override
  Future<List<Schedule>> getSchedules() async => [];
  @override
  Future<Schedule?> getById(String id) async => null;
  @override
  Future<List<Schedule>> getByVenue(String venueId) async => [];
  @override
  Future<void> addSchedule(Schedule schedule) async {}
  @override
  Future<void> addSchedules(List<Schedule> schedules) async {}
  @override
  Future<void> updateSchedule(Schedule schedule) async {}
  @override
  Future<void> deleteSchedule(String id) async {}
  @override
  Future<void> clearSchedules() async {}
}

void main() {
  group('Excel Result Template and Bulk Import', () {
    late FakeStudentRepository studentRepo;
    late FakeTeamRepository teamRepo;
    late FakeProgramRepository programRepo;
    late FakeRegistrationRepository registrationRepo;
    late FakeResultRepository resultRepo;
    late ExcelService excelService;

    setUp(() {
      studentRepo = FakeStudentRepository();
      teamRepo = FakeTeamRepository();
      programRepo = FakeProgramRepository();
      registrationRepo = FakeRegistrationRepository();
      resultRepo = FakeResultRepository();

      excelService = ExcelService(
        studentRepository: studentRepo,
        teamRepository: teamRepo,
        programRepository: programRepo,
        venueRepository: FakeVenueRepository(),
        scheduleRepository: FakeScheduleRepository(),
        registrationRepository: registrationRepo,
        resultRepository: resultRepo,
      );
    });

    test('generateResultTemplate creates valid Excel with user columns & sample row', () {
      final bytes = excelService.generateResultTemplate();
      expect(bytes, isNotEmpty);

      final excel = Excel.decodeBytes(bytes);
      expect(excel.tables.containsKey('Results_Template'), isTrue);

      final sheet = excel.tables['Results_Template']!;
      expect(sheet.maxRows, greaterThanOrEqualTo(2));

      final header = sheet.row(0).map((c) => c?.value?.toString().trim()).toList();
      expect(header, contains('Section'));
      expect(header, contains('type'));
      expect(header, contains('Program'));
      expect(header, contains('Postistion'));
      expect(header, contains('name'));
      expect(header, contains('chase number'));
      expect(header, contains('Team'));
      expect(header, contains('point'));

      final sampleRow = sheet.row(1).map((c) => c?.value?.toString().trim()).toList();
      expect(sampleRow[0], equals('Sub Junior'));
      expect(sampleRow[1], equals('non stage'));
      expect(sampleRow[2], equals('Writng Arab'));
      expect(sampleRow[3], equals('1st'));
      expect(sampleRow[4], equals('nihal'));
      expect(sampleRow[5], equals('SB6158'));
      expect(sampleRow[6], equals('Apex'));
      expect(sampleRow[7], equals('5'));
    });

    test('importResults accurately processes the user specified format', () async {
      final templateBytes = excelService.generateResultTemplate();
      final importResult = await excelService.importResults(templateBytes);

      expect(importResult.totalRows, equals(1));
      expect(importResult.validRows, equals(1));
      expect(importResult.invalidRows, equals(0));
      expect(importResult.errors, isEmpty);
      expect(importResult.validItems.length, equals(1));

      // Verify Student auto-created
      final students = await studentRepo.getStudents();
      expect(students.length, equals(1));
      expect(students.first.chaseNumber, equals('SB6158'));
      expect(students.first.name, equals('nihal'));
      expect(students.first.section, equals(FestSection.subJunior));

      // Verify Team auto-created
      final teams = await teamRepo.getTeams();
      expect(teams.length, equals(1));
      expect(teams.first.teamName, equals('Apex'));

      // Verify Program auto-created
      final programs = await programRepo.getPrograms();
      expect(programs.length, equals(1));
      expect(programs.first.programName, equals('Writng Arab'));
      expect(programs.first.isStageProgram, isFalse);
      expect(programs.first.section, equals(FestSection.subJunior));

      // Verify Result created with exact details
      final results = await resultRepo.getResults();
      expect(results.length, equals(1));
      final res = results.first;
      expect(res.position, equals(1));
      expect(res.points, equals(5));
      expect(res.status, equals(ResultStatus.published));
      expect(res.studentId, equals(students.first.id));
      expect(res.programId, equals(programs.first.id));
    });
  });
}
