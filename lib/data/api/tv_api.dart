import 'api_client.dart';
import '../models/tv_settings_model.dart';

class TvApi {
  final ApiClient client;

  TvApi(this.client);

  Future<TvSettings> getTvSettings() async {
    try {
      final res = await client.get('/tv/settings');
      if (res != null) return TvSettings.fromMap(res as Map<String, dynamic>);
    } catch (_) {}
    return TvSettings();
  }

  Future<TvSettings> updateTvSettings(TvSettings settings) async {
    try {
      final res = await client.put('/tv/settings', body: settings.toMap());
      if (res != null) return TvSettings.fromMap(res as Map<String, dynamic>);
    } catch (_) {}
    return settings;
  }

  Future<Map<String, dynamic>> getTvLive({String? section}) async {
    final queryParams = <String, String>{};
    if (section != null && section.isNotEmpty) queryParams['section'] = section;

    try {
      final res = await client.get('/tv/live', queryParams: queryParams);
      if (res != null) return res as Map<String, dynamic>;
    } catch (_) {}
    return {};
  }
}
