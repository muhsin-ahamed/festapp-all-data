import 'api_client.dart';
import '../models/program_model.dart';

class ProgramApi {
  final ApiClient client;

  ProgramApi(this.client);

  Future<List<Program>> getPrograms({String? section, String? category}) async {
    final queryParams = <String, String>{};
    if (section != null && section.isNotEmpty) queryParams['section'] = section;
    if (category != null && category.isNotEmpty) queryParams['category'] = category;

    print('[Flutter ProgramApi] GET /public/programs request - params: $queryParams');
    try {
      final res = await client.get('/public/programs', queryParams: queryParams);
      print('[Flutter ProgramApi] GET /public/programs response: $res');
      if (res is List) {
        final list = res.map((e) => Program.fromMap(e as Map<String, dynamic>)).toList();
        print('[Flutter ProgramApi] Parsed program count: ${list.length}');
        return list;
      }
      return [];
    } catch (e) {
      print('[Flutter ProgramApi] GET /public/programs error: $e');
      rethrow;
    }
  }

  Future<Program?> addProgram(Program program) async {
    final body = program.toMap();
    print('[Flutter ProgramApi] POST /controller/programs request: $body');
    try {
      final res = await client.post('/controller/programs', body: body);
      print('[Flutter ProgramApi] POST /controller/programs response: $res');
      return res != null ? Program.fromMap(res as Map<String, dynamic>) : null;
    } catch (e) {
      print('[Flutter ProgramApi] POST /controller/programs error: $e');
      rethrow;
    }
  }

  Future<Program?> updateProgram(Program program) async {
    final body = program.toMap();
    print('[Flutter ProgramApi] PUT /controller/programs/${program.id} request: $body');
    try {
      final res = await client.put('/controller/programs/${program.id}', body: body);
      print('[Flutter ProgramApi] PUT /controller/programs/${program.id} response: $res');
      return res != null ? Program.fromMap(res as Map<String, dynamic>) : null;
    } catch (e) {
      print('[Flutter ProgramApi] PUT /controller/programs/${program.id} error: $e');
      rethrow;
    }
  }

  Future<void> deleteProgram(String id) async {
    print('[Flutter ProgramApi] DELETE /controller/programs/$id request');
    try {
      await client.delete('/controller/programs/$id');
      print('[Flutter ProgramApi] DELETE /controller/programs/$id success');
    } catch (e) {
      print('[Flutter ProgramApi] DELETE /controller/programs/$id error: $e');
      rethrow;
    }
  }
}
