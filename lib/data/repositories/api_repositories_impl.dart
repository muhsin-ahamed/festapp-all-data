import '../../core/constants/app_constants.dart';
import '../models/student_model.dart';
import '../models/team_model.dart';
import '../models/program_model.dart';
import '../models/registration_model.dart';
import '../models/result_model.dart';
import 'app_repositories.dart';
import 'supabase_repositories_impl.dart';
import '../api/api_client.dart';
import '../api/student_api.dart';
import '../api/program_api.dart';
import '../api/result_api.dart';

final ApiClient globalApiClient = ApiClient();

class ApiStudentRepository implements StudentRepository {
  final StudentApi _api = StudentApi(globalApiClient);
  final SupabaseStudentRepository _supabase = SupabaseStudentRepository();

  @override
  Future<List<Student>> getStudents() async {
    try {
      final list = await _api.getStudents();
      if (list.isNotEmpty) return list;
    } catch (_) {}
    try {
      return await _supabase.getStudents();
    } catch (_) {
      return [];
    }
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
    try {
      final s = await _api.getByChaseNumber(chaseNumber);
      if (s != null) return s;
    } catch (_) {}
    try {
      return await _supabase.getByChaseNumber(chaseNumber);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Student>> getByTeam(String teamId) async {
    try {
      final list = await _api.getStudents(teamId: teamId);
      if (list.isNotEmpty) return list;
    } catch (_) {}
    try {
      return await _supabase.getByTeam(teamId);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<Student>> getBySection(FestSection section) async {
    try {
      final list = await _api.getStudents(section: section.name);
      if (list.isNotEmpty) return list;
    } catch (_) {}
    try {
      return await _supabase.getBySection(section);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> addStudent(Student student) async {
    try {
      await _api.addStudent(student);
    } catch (_) {}
    try {
      await _supabase.addStudent(student);
    } catch (_) {}
  }

  @override
  Future<void> addStudents(List<Student> students) async {
    for (final student in students) {
      await addStudent(student);
    }
  }

  @override
  Future<void> updateStudent(Student student) async {
    try {
      await _api.updateStudent(student);
    } catch (_) {}
    try {
      await _supabase.updateStudent(student);
    } catch (_) {}
  }

  @override
  Future<void> deleteStudent(String id) async {
    try {
      await _api.deleteStudent(id);
    } catch (_) {}
    try {
      await _supabase.deleteStudent(id);
    } catch (_) {}
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
  final SupabaseProgramRepository _supabase = SupabaseProgramRepository();

  @override
  Future<List<Program>> getPrograms() async {
    try {
      final list = await _api.getPrograms();
      if (list.isNotEmpty) return list;
    } catch (_) {}
    try {
      return await _supabase.getPrograms();
    } catch (_) {
      return [];
    }
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
    try {
      final list = await _api.getPrograms(section: section.name);
      if (list.isNotEmpty) return list;
    } catch (_) {}
    try {
      return await _supabase.getBySection(section);
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> addProgram(Program program) async {
    try {
      await _api.addProgram(program);
    } catch (_) {}
    try {
      await _supabase.addProgram(program);
    } catch (_) {}
  }

  @override
  Future<void> addPrograms(List<Program> programs) async {
    for (final program in programs) {
      await addProgram(program);
    }
  }

  @override
  Future<void> updateProgram(Program program) async {
    try {
      await _api.updateProgram(program);
    } catch (_) {}
    try {
      await _supabase.updateProgram(program);
    } catch (_) {}
  }

  @override
  Future<void> deleteProgram(String id) async {
    try {
      await _api.deleteProgram(id);
    } catch (_) {}
    try {
      await _supabase.deleteProgram(id);
    } catch (_) {}
  }
}

class ApiRegistrationRepository implements RegistrationRepository {
  final SupabaseRegistrationRepository _supabase =
      SupabaseRegistrationRepository();

  @override
  Future<List<Registration>> getRegistrations() async {
    try {
      final res = await globalApiClient.get('/controller/registrations');
      if (res is List) {
        final list = res
            .map((e) => Registration.fromMap(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          return list;
        }
      }
    } catch (_) {}
    try {
      return await _supabase.getRegistrations();
    } catch (_) {
      return [];
    }
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
    bool apiSuccess = false;
    try {
      final res = await globalApiClient.post(
        '/controller/registrations',
        body: {
          'id': reg.id,
          'studentId': reg.studentId,
          'programId': reg.programId,
          'teamId': reg.teamId,
          'registrationNumber': reg.registrationNumber,
          'status': reg.status.name,
        },
      );
      if (res != null) {
        apiSuccess = true;
      }
    } catch (_) {}

    // Always persist to Supabase to guarantee immediate UI visibility and durability
    try {
      await _supabase.addRegistration(reg);
    } catch (_) {
      if (!apiSuccess) rethrow;
    }
  }

  @override
  Future<void> updateRegistration(Registration reg) async {
    try {
      await _supabase.updateRegistration(reg);
    } catch (_) {}
  }

  @override
  Future<void> deleteRegistration(String id) async {
    bool apiSuccess = false;
    try {
      await globalApiClient.delete('/controller/registrations/$id');
      apiSuccess = true;
    } catch (_) {}

    try {
      await _supabase.deleteRegistration(id);
    } catch (_) {
      if (!apiSuccess) rethrow;
    }
  }
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
