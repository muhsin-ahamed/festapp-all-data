import 'api_client.dart';
import '../models/user_model.dart';

class AuthApi {
  final ApiClient client;

  AuthApi(this.client);

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await client.post('/auth/login', body: {
      'username': username,
      'password': password,
    });
    
    if (response is Map) {
      final token = response['accessToken'] ?? response['token'];
      if (token != null && token is String) {
        client.setAuthToken(token);
      }
      return Map<String, dynamic>.from(response);
    }
    
    return {};
  }

  Future<User?> getMe() async {
    final res = await client.get('/auth/me');
    return res != null ? User.fromMap(res as Map<String, dynamic>) : null;
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await client.post('/auth/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<User?> updateUsername(String newUsername) async {
    final res = await client.put('/auth/username', body: {
      'username': newUsername,
    });
    return res != null ? User.fromMap(res as Map<String, dynamic>) : null;
  }

  void logout() {
    client.setAuthToken(null);
  }
}
