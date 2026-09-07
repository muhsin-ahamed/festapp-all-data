import '../../core/constants/app_constants.dart';
import '../models/student_model.dart';
import '../models/team_model.dart';
import '../models/program_model.dart';
import '../models/registration_model.dart';
import '../models/result_model.dart';
import 'app_repositories.dart';
import '../api/api_client.dart';
import '../api/student_api.dart';
import '../api/program_api.dart';
import '../api/result_api.dart';

final ApiClient globalApiClient = ApiClient();

class ApiStudentRepository implements StudentRepository {
  final StudentApi _api = StudentApi(globalApiClient);

  @override
  Future<List<Student>> getStudents() async {
    return await _api.getStudents();
  }

  @override
  Future<Student?> getById(String id) async {
    final students = await getStudents();
    try {
      return students.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Student?> getByChaseNumber(String chaseNumber) async {
    return await _api.getByChaseNumber(chaseNumber);
  }

  @override
  Future<List<Student>> getByTeam(String teamId) async {
    return await _api.getStudents(teamId: teamId);
  }

  @override
  Future<List<Student>> getBySection(FestSection section) async {
    return await _api.getStudents(section: section.name);
  }

  @override
  Future<void> addStudent(Student student) async {
    await _api.addStudent(student);
  }

  @override
  Future<void> addStudents(List<Student> students) async {
    for (final student in students) {
      await _api.addStudent(student);
    }
  }

  @override
  Future<void> updateStudent(Student student) async {
    await _api.updateStudent(student);
  }

  @override
  Future<void> deleteStudent(String id) async {
    await _api.deleteStudent(id);
  }
}

class ApiTeamRepository implements TeamRepository {
  @override
  Future<List<Team>> getTeams() async {
    try {
      final res = await globalApiClient.get('/public/teams');
      if (res is List) {
        return res.map((e) => Team.fromMap(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<Team?> getById(String id) async {
    final teams = await getTeams();
    try {
      return teams.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Team?> getByCode(String code) async {
    final teams = await getTeams();
    try {
      return teams.firstWhere(
        (t) => t.teamCode.toLowerCase() == code.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> addTeam(Team team) async {
    await globalApiClient.post('/controller/teams', body: team.toMap());
  }

  @override
  Future<void> addTeams(List<Team> teams) async {
    for (final team in teams) {
      await addTeam(team);
    }
  }

  @override
  Future<void> updateTeam(Team team) async {
    await globalApiClient.put(
      '/controller/teams/${team.id}',
      body: team.toMap(),
    );
  }

  @override
  Future<void> deleteTeam(String id) async {
    await globalApiClient.delete('/controller/teams/$id');
  }
}

class ApiProgramRepository implements ProgramRepository {
  final ProgramApi _api = ProgramApi(globalApiClient);

  @override
  Future<List<Program>> getPrograms() async {
    return await _api.getPrograms();
  }

  @override
  Future<Program?> getById(String id) async {
    final programs = await getPrograms();
    try {
      return programs.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Program?> getByCode(String code) async {
    final programs = await getPrograms();
    try {
      return programs.firstWhere(
        (p) => p.programCode.toLowerCase() == code.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Program>> getBySection(FestSection section) async {
    return await _api.getPrograms(section: section.name);
  }

  @override
  Future<void> addProgram(Program program) async {
    await _api.addProgram(program);
  }

  @override
  Future<void> addPrograms(List<Program> programs) async {
    for (final program in programs) {
      await addProgram(program);
    }
  }

  @override
  Future<void> updateProgram(Program program) async {
    await _api.updateProgram(program);
  }

  @override
  Future<void> deleteProgram(String id) async {
    await _api.deleteProgram(id);
  }
}

class ApiRegistrationRepository implements RegistrationRepository {
  @override
  Future<List<Registration>> getRegistrations() async {
    try {
      final res = await globalApiClient.get('/controller/registrations');
      if (res is List) {
        return res
            .map((e) => Registration.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
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
  Future<Registration?> getByStudentAndProgram(
    String studentId,
    String programId,
  ) async {
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
    try {
      await globalApiClient.post(
        '/leader/registrations',
        body: {'studentId': reg.studentId, 'programId': reg.programId},
      );
    } catch (_) {}
  }

  @override
  Future<void> updateRegistration(Registration reg) async {}

  @override
  Future<void> deleteRegistration(String id) async {}
}

class ApiResultRepository implements ResultRepository {
  final ResultApi _api = ResultApi(globalApiClient);

  @override
  Future<List<Result>> getResults() async {
    return await _api.getResults();
  }

  @override
  Future<List<Result>> getPublishedResults() async {
    return await _api.getPublishedResults();
  }

  @override
  Future<List<Result>> getByProgram(String programId) async {
    return await _api.getResults(programId: programId);
  }

  @override
  Future<List<Result>> getByStudent(String studentId) async {
    return await _api.getResults(studentId: studentId);
  }

  @override
  Future<List<Result>> getByTeam(String teamId) async {
    return await _api.getResults(teamId: teamId);
  }

  @override
  Future<Result?> getById(String id) async {
    final results = await getResults();
    try {
      return results.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveResult(Result result) async {
    await _api.submitJuryResult(
      programId: result.programId,
      studentId: result.studentId,
      marks: result.marks,
      grade: result.grade,
      position: result.position,
      remarks: result.remarks,
      isDraft: result.status == ResultStatus.draft,
    );
  }

  @override
  Future<void> updateResult(Result result) async {
    await saveResult(result);
  }

  @override
  Future<void> deleteResult(String id) async {}
}
