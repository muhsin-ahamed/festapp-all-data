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

  static QrScanResult parseQrPayload(String payload) {
    final clean = payload.trim();
    if (clean.startsWith('fest_program:')) {
      final progId = clean.replaceFirst('fest_program:', '');
      return QrScanResult(type: QrScanType.program, value: progId);
    } else if (clean.startsWith('fest_jury:')) {
      final code = clean.replaceFirst('fest_jury:', '');
      return QrScanResult(type: QrScanType.jury, value: code);
    } else {
      // Default assume Student Chase Number
      return QrScanResult(type: QrScanType.studentChaseNumber, value: clean);
    }
  }
}

enum QrScanType { studentChaseNumber, program, jury }

class QrScanResult {
  final QrScanType type;
  final String value;

  QrScanResult({required this.type, required this.value});
}
