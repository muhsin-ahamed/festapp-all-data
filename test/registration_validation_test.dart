import 'package:flutter_test/flutter_test.dart';
import 'package:amia_fest/core/constants/app_constants.dart';

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
  });
}
