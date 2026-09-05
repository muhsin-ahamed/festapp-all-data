import 'api_client.dart';
import '../models/result_model.dart';

class ResultApi {
  final ApiClient client;

  ResultApi(this.client);

  Future<List<Result>> getResults({String? section, String? programId, String? studentId, String? teamId, String? status}) async {
    final queryParams = <String, String>{};
    if (section != null && section.isNotEmpty) queryParams['section'] = section;
    if (programId != null && programId.isNotEmpty) queryParams['programId'] = programId;
    if (studentId != null && studentId.isNotEmpty) queryParams['studentId'] = studentId;
    if (teamId != null && teamId.isNotEmpty) queryParams['teamId'] = teamId;
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    try {
      final res = await client.get('/controller/results', queryParams: queryParams);
      if (res is List) {
        return res.map((e) => Result.fromMap(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      return getPublishedResults(section: section, programId: programId);
    }
    return [];
  }

  Future<List<Result>> getPublishedResults({String? section, String? programId}) async {
    final queryParams = <String, String>{};
    if (section != null && section.isNotEmpty) queryParams['section'] = section;
    if (programId != null && programId.isNotEmpty) queryParams['programId'] = programId;

    try {
      final res = await client.get('/public/results', queryParams: queryParams);
      if (res is List) {
        return res.map((e) => Result.fromMap(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Result?> submitJuryResult({
    required String programId,
    required String studentId,
    required double marks,
    String? grade,
    int? position,
    String? remarks,
    bool isDraft = false,
  }) async {
    try {
      final res = await client.post('/jury/results', body: {
        'programId': programId,
        'studentId': studentId,
        'marks': marks,
        'grade': grade,
        'position': position,
        'remarks': remarks,
        'isDraft': isDraft,
      });
      return res != null ? Result.fromMap(res as Map<String, dynamic>) : null;
    } catch (_) {
      return null;
    }
  }

  Future<Result?> verifyResult(String resultId) async {
    try {
      final res = await client.post('/controller/results/verify/$resultId');
      return res != null ? Result.fromMap(res as Map<String, dynamic>) : null;
    } catch (_) {
      return null;
    }
  }

  Future<Result?> publishResult(String resultId) async {
    try {
      final res = await client.post('/controller/results/publish/$resultId');
      return res != null ? Result.fromMap(res as Map<String, dynamic>) : null;
    } catch (_) {
      return null;
    }
  }
}
