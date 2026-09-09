import 'package:flutter_test/flutter_test.dart';
import 'package:amia_fest/core/constants/app_constants.dart';
import 'package:amia_fest/data/models/registration_model.dart';
import 'package:amia_fest/data/models/student_model.dart';

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
        'student_id': 's_2',
        'program_id': 'p_2',
        'team_id': 't_2',
        'registration_number': 'REG-SB7882-P01',
        'status': 'approved',
        'created_at': '2026-09-09T00:00:00.000Z',
      });
      expect(regWithSnakeCase.id, equals('reg_2'));
      expect(regWithSnakeCase.studentId, equals('s_2'));
      expect(regWithSnakeCase.programId, equals('p_2'));
      expect(regWithSnakeCase.teamId, equals('t_2'));
      expect(regWithSnakeCase.registrationNumber, equals('REG-SB7882-P01'));
      expect(regWithSnakeCase.createdAt.year, equals(2026));
    });

    test('Student.fromMap parses chase number with alternate keys', () {
      final s1 = Student.fromMap({
        'id': 's_100',
        'chase_number': 'SB7882',
        'name': 'Ahmad',
      });
      expect(s1.chaseNumber, equals('SB7882'));
      expect(s1.section, equals(FestSection.subJunior));

      final s2 = Student.fromMap({
        'id': 's_200',
        'chest_no': 'J-105',
        'name': 'Bilal',
      });
      expect(s2.chaseNumber, equals('J-105'));
    });

    test('Scheduled programs sort before unscheduled programs', () {
      final items = [
        {'name': 'Program B', 'hasSchedule': false},
        {'name': 'Program A', 'hasSchedule': true, 'time': '10:00'},
        {'name': 'Program C', 'hasSchedule': true, 'time': '09:00'},
      ];

      items.sort((a, b) {
        final aSched = a['hasSchedule'] as bool;
        final bSched = b['hasSchedule'] as bool;
        if (aSched && !bSched) return -1;
        if (!aSched && bSched) return 1;
        if (aSched && bSched) {
          return (a['time'] as String).compareTo(b['time'] as String);
        }
        return (a['name'] as String).compareTo(b['name'] as String);
      });

      expect(items[0]['name'], equals('Program C')); // scheduled at 09:00
      expect(items[1]['name'], equals('Program A')); // scheduled at 10:00
      expect(items[2]['name'], equals('Program B')); // unscheduled
    });

    test('Date and Day formatting parses date and weekday correctly', () {
      final parsed = DateTime.tryParse('2026-09-10');
      expect(parsed, isNotNull);
      const weekdays = [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
      ];
      final weekday = weekdays[parsed!.weekday - 1];
      expect(weekday, equals('Thursday'));
    });
  });
}
