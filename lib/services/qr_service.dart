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

  static String generateJuryLoginProgramQrPayload(String username, String password, String programId) {
    return 'fest_jury_login:$username:$password:$programId';
  }

  static QrScanResult parseQrPayload(String payload) {
    final clean = payload.trim();
    if (clean.startsWith('fest_program:')) {
      final progId = clean.replaceFirst('fest_program:', '');
      return QrScanResult(type: QrScanType.program, value: progId);
    } else if (clean.startsWith('fest_jury_login:')) {
      final parts = clean.split(':');
      if (parts.length >= 4) {
        return QrScanResult(
          type: QrScanType.juryLoginProgram,
          value: clean,
          username: parts[1],
          password: parts[2],
          programId: parts[3],
        );
      }
      return QrScanResult(type: QrScanType.juryLoginProgram, value: clean);
    } else if (clean.startsWith('fest_jury:')) {
      final code = clean.replaceFirst('fest_jury:', '');
      return QrScanResult(type: QrScanType.jury, value: code);
    } else {
      // Default assume Student Chase Number
      return QrScanResult(type: QrScanType.studentChaseNumber, value: clean);
    }
  }
}

enum QrScanType { studentChaseNumber, program, jury, juryLoginProgram }

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
