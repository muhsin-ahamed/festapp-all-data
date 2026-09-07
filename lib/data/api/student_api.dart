import 'api_client.dart';
import '../models/student_model.dart';

class StudentApi {
  final ApiClient client;

  StudentApi(this.client);

  Future<List<Student>> getStudents({
    String? teamId,
    String? section,
    String? query,
  }) async {
    final queryParams = <String, String>{};
    if (teamId != null && teamId.isNotEmpty) queryParams['teamId'] = teamId;
    if (section != null && section.isNotEmpty) queryParams['section'] = section;
    if (query != null && query.isNotEmpty) queryParams['query'] = query;

    try {
      final res = await client.get(
        '/controller/students',
        queryParams: queryParams,
      );
      if (res is List) {
        return res
            .map((e) => Student.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Student?> getByChaseNumber(String chaseNumber) async {
    try {
      final res = await client.get('/public/student/$chaseNumber');
      return res != null ? Student.fromMap(res as Map<String, dynamic>) : null;
    } catch (_) {
      return null;
    }
  }

  Future<Student?> addStudent(Student student) async {
    try {
      final res = await client.post(
        '/controller/students',
        body: student.toMap(),
      );
      return res != null ? Student.fromMap(res as Map<String, dynamic>) : null;
    } catch (_) {
      return null;
    }
  }

  Future<Student?> updateStudent(Student student) async {
    try {
      final res = await client.put(
        '/controller/students/${student.id}',
        body: student.toMap(),
      );
      return res != null ? Student.fromMap(res as Map<String, dynamic>) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      await client.delete('/controller/students/$id');
    } catch (_) {}
  }
}
