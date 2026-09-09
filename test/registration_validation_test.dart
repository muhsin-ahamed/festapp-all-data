import 'package:flutter_test/flutter_test.dart';
import 'package:amia_fest/core/constants/app_constants.dart';
import 'package:amia_fest/data/models/registration_model.dart';

void main() {
  group('Registration Limit Validation Unit Tests', () {
    test('Non-stage program maximum limit is 4', () {
      expect(AppConstants.maxNonStagePerStudent, equals(4));
    });

    test('Stage program maximum limit is 3', () {
      expect(AppConstants.maxStagePerStudent, equals(3));
    });

    test('Validation prevents registration beyond non-stage limit', () {
      int nonStageCount = 4;
      bool canRegister = nonStageCount < AppConstants.maxNonStagePerStudent;
      expect(canRegister, isFalse);
    });

    test('Validation prevents registration beyond stage limit', () {
      int stageCount = 3;
      bool canRegister = stageCount < AppConstants.maxStagePerStudent;
      expect(canRegister, isFalse);
    });

    test(
      'General program does not consume section stage/non-stage slot limits',
      () {
        bool canRegister(bool isGen, int count) =>
            isGen ? true : count < AppConstants.maxNonStagePerStudent;
        expect(canRegister(true, 4), isTrue);
        expect(canRegister(false, 4), isFalse);
      },
    );

    test('Parses section "SUB JUNOR" to subJunior', () {
      expect(FestSection.fromString('SUB JUNOR'), equals(FestSection.subJunior));
      expect(FestSection.fromString(' SUB JUNOR '), equals(FestSection.subJunior));
      expect(
        FestSection.fromString('SUB JUNOR', 'SB7882'),
        equals(FestSection.subJunior),
      );
      expect(
        FestSection.fromString('SUB JUNOR', 'SB7165'),
        equals(FestSection.subJunior),
      );
    });

    test('Parses chest numbers with SB prefix to subJunior', () {
      expect(FestSection.fromString('', 'SB7882'), equals(FestSection.subJunior));
      expect(FestSection.fromString('', 'SB7165'), equals(FestSection.subJunior));
    });

    test('Registration toMap does not contain createdAt to prevent Supabase PGRST204 error', () {
      final reg = Registration(
        id: 'reg_123',
        studentId: 'stud_123',
        programId: 'prog_123',
        teamId: 'team_123',
        registrationNumber: 'REG-SB7882-P01',
        status: RegistrationStatus.approved,
      );

      final map = reg.toMap();
      expect(map.containsKey('createdAt'), isFalse);
      expect(map.containsKey('created_at'), isFalse);
      expect(map['id'], equals('reg_123'));
      expect(map['studentId'], equals('stud_123'));
      expect(map['programId'], equals('prog_123'));
      expect(map['teamId'], equals('team_123'));
      expect(map['registrationNumber'], equals('REG-SB7882-P01'));
      expect(map['status'], equals('approved'));
    });

    test('Registration fromMap handles missing or present timestamp gracefully', () {
      final regNoTimestamp = Registration.fromMap({
        'id': 'reg_1',
        'studentId': 's_1',
        'programId': 'p_1',
        'teamId': 't_1',
        'registrationNumber': 'REG-001',
        'status': 'approved',
      });
      expect(regNoTimestamp.id, equals('reg_1'));
      expect(regNoTimestamp.createdAt, isNotNull);

      final regWithSnakeCase = Registration.fromMap({
        'id': 'reg_2',
        'studentId': 's_2',
        'programId': 'p_2',
        'teamId': 't_2',
        'registrationNumber': 'REG-002',
        'status': 'approved',
        'created_at': '2026-09-09T00:00:00.000Z',
      });
      expect(regWithSnakeCase.id, equals('reg_2'));
      expect(regWithSnakeCase.createdAt.year, equals(2026));
    });
  });
}
