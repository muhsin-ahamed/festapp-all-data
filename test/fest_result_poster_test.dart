import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amia_fest/core/widgets/fest_result_poster.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FestResultPoster Widget Tests', () {
    testWidgets('renders program name, section, result number, and winners correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FestResultPoster(
              resultNumber: '17',
              programName: 'WRITING URD',
              sectionLabel: 'SUB JUNIOR',
              winner1: FestResultWinner(
                position: 1,
                studentName: 'NIHAL A',
                chaseNumber: 'SB6158',
                teamName: 'Telos',
              ),
              winner2: FestResultWinner(
                position: 2,
                studentName: 'FARIS',
                chaseNumber: 'SB7083',
                teamName: 'Apex',
              ),
              winner3: FestResultWinner(
                position: 3,
                studentName: 'Sahad',
                chaseNumber: 'SB6073',
                teamName: 'Apex',
              ),
              revealedPositions: {1, 2, 3},
              isRevealMode: false,
            ),
          ),
        ),
      );

      // Verify text elements
      expect(find.text('17'), findsOneWidget);
      expect(find.text('WRITING URD'), findsOneWidget);
      expect(find.text('SUB JUNIOR'), findsOneWidget);
      expect(find.text('NIHAL A'), findsOneWidget);
      expect(find.text('#SB6158'), findsOneWidget);
      expect(find.text('• Telos'), findsOneWidget);
      expect(find.text('FARIS'), findsOneWidget);
      expect(find.text('#SB7083'), findsOneWidget);
      expect(find.text('• Apex'), findsNWidgets(2)); // Both 2nd and 3rd are Apex
      expect(find.text('Sahad'), findsOneWidget);
      expect(find.text('#SB6073'), findsOneWidget);
    });

    testWidgets('respects reveal mode by hiding unrevealed positions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FestResultPoster(
              resultNumber: '17',
              programName: 'WRITING URD',
              sectionLabel: 'SUB JUNIOR',
              winner1: FestResultWinner(
                position: 1,
                studentName: 'NIHAL A',
                chaseNumber: 'SB6158',
                teamName: 'Telos',
              ),
              winner2: FestResultWinner(
                position: 2,
                studentName: 'FARIS',
                chaseNumber: 'SB7083',
                teamName: 'Apex',
              ),
              winner3: FestResultWinner(
                position: 3,
                studentName: 'Sahad',
                chaseNumber: 'SB6073',
                teamName: 'Apex',
              ),
              revealedPositions: {3}, // Only 3rd place revealed so far
              isRevealMode: true,
            ),
          ),
        ),
      );

      // AnimatedOpacity for 3rd place should be 1.0, and 0.0 for 1st and 2nd
      final opacities = tester.widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity)).toList();
      expect(opacities.length, 3);
      expect(opacities[0].opacity, 0.0); // 1st hidden
      expect(opacities[1].opacity, 0.0); // 2nd hidden
      expect(opacities[2].opacity, 1.0); // 3rd revealed
    });
  });
}
