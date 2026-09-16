import 'package:flutter_test/flutter_test.dart';
import 'package:amia_fest/services/qr_service.dart';

void main() {
  group('QrService Login Payload Parsing Unit Tests', () {
    test('Parses fest_jury_login with trailing empty programId', () {
      final res = QrService.parseQrPayload('fest_jury_login:jury1:jury123:');
      expect(res.type, QrScanType.juryLoginProgram);
      expect(res.username, 'jury1');
      expect(res.password, 'jury123');
      expect(res.programId, isNull);
    });

    test('Parses fest_jury_login with specific programId', () {
      final res = QrService.parseQrPayload('fest_jury_login:jury1:jury123:prog_101');
      expect(res.type, QrScanType.juryLoginProgram);
      expect(res.username, 'jury1');
      expect(res.password, 'jury123');
      expect(res.programId, 'prog_101');
    });

    test('Parses general user login fest_login', () {
      final res = QrService.parseQrPayload('fest_login:ksams:Acsmr@7012');
      expect(res.type, QrScanType.userLogin);
      expect(res.username, 'ksams');
      expect(res.password, 'Acsmr@7012');
    });

    test('Parses JSON login QR payload', () {
      final jsonStr = '{"username": "jury1", "password": "jury123", "role": "jury"}';
      final res = QrService.parseQrPayload(jsonStr);
      expect(res.type, QrScanType.juryLoginProgram);
      expect(res.username, 'jury1');
      expect(res.password, 'jury123');
    });

    test('Parses fest_jury code QR payload', () {
      final res = QrService.parseQrPayload('fest_jury:JURY-101');
      expect(res.type, QrScanType.jury);
      expect(res.value, 'JURY-101');
      expect(res.username, 'JURY-101');
    });

    test('Parses standard credential pair username:password', () {
      final res = QrService.parseQrPayload('leader1:leader123');
      expect(res.type, QrScanType.userLogin);
      expect(res.username, 'leader1');
      expect(res.password, 'leader123');
    });

    test('Parses student chase number fallback', () {
      final res = QrService.parseQrPayload('S-204');
      expect(res.type, QrScanType.studentChaseNumber);
      expect(res.value, 'S-204');
    });
  });
}
