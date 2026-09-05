import 'api_client.dart';
import '../models/student_model.dart';
import '../models/program_model.dart';
import '../models/registration_model.dart';
import '../models/result_model.dart';
import '../models/team_model.dart';

class LeaderApi {
  final ApiClient client;

  LeaderApi(this.client);

  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final res = await client.get('/leader/dashboard');
      if (res != null) return res as Map<String, dynamic>;
    } catch (_) {}
    return {};
  }

  Future<Team?> getTeam() async {
    try {
      final res = await client.get('/leader/team');
      return res != null ? Team.fromMap(res as Map<String, dynamic>) : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<Student>> getTeamStudents({String? section}) async {
    final queryParams = <String, String>{};
    if (section != null && section.isNotEmpty) queryParams['section'] = section;

    try {
      final res = await client.get('/leader/students', queryParams: queryParams);
      if (res is List) {
        return res.map((e) => Student.fromMap(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Student?> addStudent(Student student) async {
    try {
      final res = await client.post('/leader/students', body: student.toMap());
      return res != null ? Student.fromMap(res as Map<String, dynamic>) : null;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> importStudentsExcel(List<int> bytes) async {
    try {
      final res = await client.post('/leader/students/import-excel', body: {'buffer': bytes});
      if (res is Map<String, dynamic>) return res;
    } catch (_) {}
    return null;
  }

  Future<List<Program>> getSectionPrograms(String section) async {
    try {
      final res = await client.get('/leader/programs', queryParams: {'section': section});
      if (res is List) {
        return res.map((e) => Program.fromMap(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Registration?> createRegistration(String studentId, String programId) async {
    try {
      final res = await client.post('/leader/registrations', body: {
        'studentId': studentId,
        'programId': programId,
      });
      return res != null ? Registration.fromMap(res as Map<String, dynamic>) : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<Registration>> getRegistrations() async {
    try {
      final res = await client.get('/leader/registrations');
      if (res is List) {
        return res.map((e) => Registration.fromMap(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<Result>> getTeamResults() async {
    try {
      final res = await client.get('/leader/results');
      if (res is List) {
        return res.map((e) => Result.fromMap(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }
}
