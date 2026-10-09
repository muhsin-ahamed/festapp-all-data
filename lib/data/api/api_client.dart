import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://festapp-all-data.onrender.com/api',
  );
  final String baseUrl;
  String? _authToken;

  static String _formatBaseUrl(String url) {
    var formatted = url.trim();
    if (formatted.endsWith('/')) {
      formatted = formatted.substring(0, formatted.length - 1);
    }
    if (!formatted.endsWith('/api')) {
      return '$formatted/api';
    }
    return formatted;
  }

  ApiClient({String? baseUrl})
    : baseUrl = _formatBaseUrl(baseUrl ?? defaultBaseUrl);

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  Map<String, String> _headers({Map<String, String>? extraHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  dynamic _processResponse(http.Response response) {
    final statusCode = response.statusCode;
    final bodyString = response.body;

    dynamic jsonBody;
    try {
      jsonBody = jsonDecode(bodyString);
    } catch (_) {
      jsonBody = null;
    }

    if (statusCode >= 200 && statusCode < 300) {
      if (jsonBody != null && jsonBody is Map && jsonBody.containsKey('data')) {
        return jsonBody['data'];
      }
      return jsonBody;
    } else {
      final message = (jsonBody is Map && jsonBody['message'] != null)
          ? jsonBody['message'].toString()
          : 'HTTP Request failed with status $statusCode';
      throw ApiException(message: message, statusCode: statusCode);
    }
  }

  Future<dynamic> _wrapRequest(Future<http.Response> Function() fn) async {
    try {
      final response = await fn();
      return _processResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('Failed to fetch') ||
          errStr.contains('ClientException') ||
          errStr.contains('SocketException')) {
        final isLocal = baseUrl.contains('localhost') || baseUrl.contains('127.0.0.1');
        final hint = isLocal
            ? 'Please verify Node.js server is running locally.'
            : 'Please verify the backend server URL is reachable and CORS is configured.';
        throw ApiException(
          message: 'Failed to connect to backend at $baseUrl. $hint',
          statusCode: 0,
        );
      }
      throw ApiException(
        message: errStr.replaceFirst(RegExp(r'^Exception:\s*'), ''),
        statusCode: 500,
      );
    }
  }

  Future<dynamic> get(String path, {Map<String, String>? queryParams}) async {
    return _wrapRequest(() async {
      Uri uri = Uri.parse('$baseUrl$path');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }
      return await http.get(uri, headers: _headers());
    });
  }

  Future<dynamic> post(String path, {dynamic body}) async {
    return _wrapRequest(() async {
      final uri = Uri.parse('$baseUrl$path');
      return await http.post(
        uri,
        headers: _headers(),
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  Future<dynamic> put(String path, {dynamic body}) async {
    return _wrapRequest(() async {
      final uri = Uri.parse('$baseUrl$path');
      return await http.put(
        uri,
        headers: _headers(),
        body: body != null ? jsonEncode(body) : null,
      );
    });
  }

  Future<dynamic> delete(String path) async {
    return _wrapRequest(() async {
      final uri = Uri.parse('$baseUrl$path');
      return await http.delete(uri, headers: _headers());
    });
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException({required this.message, required this.statusCode});

  @override
  String toString() => message;
}
