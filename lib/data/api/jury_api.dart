import 'api_client.dart';
import '../models/program_model.dart';
import '../models/registration_model.dart';
import '../models/result_model.dart';

class JuryApi {
  final ApiClient client;

  JuryApi(this.client);

  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final res = await client.get('/jury/dashboard');
      if (res != null) return res as Map<String, dynamic>;
    } catch (_) {}
    return {};
  }

  Future<List<Program>> getAssignedPrograms() async {
    try {
      final res = await client.get('/jury/programs');
      if (res is List) {
        return res
            .map((e) => Program.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<List<Registration>> getProgramParticipants(String programId) async {
    try {
      final res = await client.get('/jury/programs/$programId/participants');
      if (res is List) {
        return res
            .map((e) => Registration.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>> scanQrCode(String payload) async {
    try {
      final res = await client.post('/jury/scan', body: {'payload': payload});
      if (res != null) return res as Map<String, dynamic>;
    } catch (_) {}
    return {};
  }

  Future<List<Result>> getJuryResults() async {
    try {
      final res = await client.get('/jury/results');
      if (res is List) {
        return res
            .map((e) => Result.fromMap(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
