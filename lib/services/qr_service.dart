import 'dart:convert';

class QrService {
  static String generateStudentQrPayload(String chaseNumber) {
    return chaseNumber.trim();
  }

  static String generateProgramJuryQrPayload(String programId) {
    return 'fest_program:$programId';
  }

  static String generateJuryLoginQrPayload(String juryCode) {
    return 'fest_jury:$juryCode';
  }

  static String generateJuryLoginProgramQrPayload(
    String username,
    String password,
    String programId,
  ) {
    return 'fest_jury_login:$username:$password:$programId';
  }

  static String generateUserLoginQrPayload(
    String username,
    String password,
  ) {
    return 'fest_login:$username:$password';
  }

  static QrScanResult parseQrPayload(String payload) {
    final clean = payload.trim();
    if (clean.isEmpty) {
      return QrScanResult(type: QrScanType.studentChaseNumber, value: '');
    }

    // 1. Program scan: fest_program:<progId>
    if (clean.startsWith('fest_program:')) {
      final progId = clean.replaceFirst('fest_program:', '').trim();
      return QrScanResult(type: QrScanType.program, value: progId);
    }

    // 2. Jury Login Program scan: fest_jury_login:<username>:<password>[:<programId>]
    if (clean.startsWith('fest_jury_login:')) {
      final parts = clean.split(':');
      final username = parts.length > 1 ? parts[1].trim() : null;
      final password = parts.length > 2 ? parts[2].trim() : null;
      final programId =
          parts.length > 3 && parts[3].trim().isNotEmpty ? parts[3].trim() : null;

      return QrScanResult(
        type: QrScanType.juryLoginProgram,
        value: clean,
        username: username,
        password: password,
        programId: programId,
      );
    }

    // 3. General User Login scan: fest_login:<username>:<password>, etc.
    if (clean.startsWith('fest_login:') ||
        clean.startsWith('fest_user_login:') ||
        clean.startsWith('fest_user:') ||
        clean.startsWith('fest_auth:')) {
      final parts = clean.split(':');
      final username = parts.length > 1 ? parts[1].trim() : null;
      final password = parts.length > 2 ? parts[2].trim() : null;
      return QrScanResult(
        type: QrScanType.userLogin,
        value: clean,
        username: username,
        password: password,
      );
    }

    // 4. Jury code scan: fest_jury:<juryCode>
    if (clean.startsWith('fest_jury:')) {
      final code = clean.replaceFirst('fest_jury:', '').trim();
      return QrScanResult(
        type: QrScanType.jury,
        value: code,
        username: code,
      );
    }

    // 5. JSON format login QR: e.g. {"username": "...", "password": "...", ...}
    if (clean.startsWith('{') && clean.endsWith('}')) {
      try {
        final decoded = jsonDecode(clean);
        if (decoded is Map<String, dynamic>) {
          final username = (decoded['username'] ??
                  decoded['user'] ??
                  decoded['u'])
              ?.toString()
              .trim();
          final password = (decoded['password'] ??
                  decoded['pass'] ??
                  decoded['p'])
              ?.toString()
              .trim();
          final programId = (decoded['programId'] ??
                  decoded['program'] ??
                  decoded['progId'])
              ?.toString()
              .trim();
          final role = decoded['role']?.toString().toLowerCase();

          if (username != null && username.isNotEmpty) {
            return QrScanResult(
              type: role == 'jury' || (programId != null && programId.isNotEmpty)
                  ? QrScanType.juryLoginProgram
                  : QrScanType.userLogin,
              value: clean,
              username: username,
              password: password,
              programId:
                  (programId != null && programId.isNotEmpty) ? programId : null,
            );
          }
        }
      } catch (_) {}
    }

    // 6. Plain credential pair formatted as "username:password" (no spaces, exactly 2 parts)
    if (clean.contains(':') &&
        !clean.contains(' ') &&
        !clean.startsWith('http://') &&
        !clean.startsWith('https://')) {
      final colonIndex = clean.indexOf(':');
      final username = clean.substring(0, colonIndex).trim();
      final password = clean.substring(colonIndex + 1).trim();
      if (username.isNotEmpty && password.isNotEmpty && !username.contains(':')) {
        return QrScanResult(
          type: QrScanType.userLogin,
          value: clean,
          username: username,
          password: password,
        );
      }
    }

    // 7. Default assume Student Chase Number or Query
    return QrScanResult(type: QrScanType.studentChaseNumber, value: clean);
  }
}

enum QrScanType { studentChaseNumber, program, jury, juryLoginProgram, userLogin }

class QrScanResult {
  final QrScanType type;
  final String value;
  final String? username;
  final String? password;
  final String? programId;

  QrScanResult({
    required this.type,
    required this.value,
    this.username,
    this.password,
    this.programId,
  });
}
