import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amia_fest/features/tv/tv_portal_screen.dart';
import 'package:amia_fest/core/providers/app_providers.dart';
import 'package:amia_fest/core/constants/app_constants.dart';
import 'package:amia_fest/data/models/tv_settings_model.dart';
import 'package:amia_fest/data/models/program_model.dart';
import 'package:amia_fest/data/models/result_model.dart';
import 'package:amia_fest/data/models/student_model.dart';
import 'package:amia_fest/data/models/team_model.dart';
import 'package:amia_fest/data/repositories/app_repositories.dart';
import 'package:amia_fest/services/tv_service.dart';
import 'package:amia_fest/core/widgets/fest_result_poster.dart';

class FakeTvSettingsRepo implements TvSettingsRepository {
  final TvSettings _settings;
  FakeTvSettingsRepo(this._settings);

  @override
  Future<TvSettings> getSettings() async => _settings;

  @override
  Future<void> updateSettings(TvSettings settings) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TV Results slide renders FestResultPoster full screen without brown background or old header', (tester) async {
    final tvSettings = TvSettings(
      screenMode: 'RESULTS',
      autoRotate: false,
      slideDuration: 10,
      revealedPositions: [1, 2, 3],
    );

    final fakeTvRepo = FakeTvSettingsRepo(tvSettings);
    final tvService = TvService(tvSettingsRepository: fakeTvRepo);

    final testProgram = Program(
      id: 'prog1',
      programCode: '139',
      programName: 'AI POSTER DESIGN',
      category: ProgramCategory.nonStage,
      section: FestSection.senior,
      isStageProgram: true,
      isGeneral: false,
      status: 'COMPLETED',
      duration: '60 mins',
    );

    final testResult = Result(
      id: 'res1',
      programId: 'prog1',
      studentId: 'stud1',
      teamId: 'team1',
      position: 1,
      grade: 'A',
      status: ResultStatus.published,
      createdAt: DateTime.now(),
      publishedAt: DateTime.now(),
    );

    final testStudent = Student(
      id: 'stud1',
      name: 'YASEEN',
      chaseNumber: 'SR4178',
      gender: 'Male',
      dateOfBirth: '2005-01-01',
      teamId: 'team1',
      section: FestSection.senior,
      phone: '1234567890',
      className: '10',
      schoolName: 'School',
    );

    final testTeam = Team(
      id: 'team1',
      teamName: 'Telos',
      teamCode: 'TEL',
      totalPoints: 100,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tvServiceProvider.overrideWith((ref) => tvService),
          publishedResultsProvider.overrideWith((ref) async => [testResult]),
          resultsProvider.overrideWith((ref) async => [testResult]),
          programsProvider.overrideWith((ref) async => [testProgram]),
          studentsProvider.overrideWith((ref) async => [testStudent]),
          teamsProvider.overrideWith((ref) async => [testTeam]),
          announcementsProvider.overrideWith((ref) async => []),
        ],
        child: const MaterialApp(
          home: TvPortalScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify FestResultPoster is displayed
    expect(find.byType(FestResultPoster), findsOneWidget);
    expect(find.text('AI POSTER DESIGN'), findsOneWidget);
    expect(find.text('139'), findsOneWidget);
    expect(find.text('YASEEN'), findsOneWidget);

    // Verify the Scaffold background is cream Color(0xFFF8F6E7)
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, const Color(0xFFF8F6E7));

    // Verify old header texts from Image 2 are NOT shown
    expect(find.text('LIVE DISPLAY PORTAL'), findsNothing);
    expect(find.text('RESULTS'), findsNothing);
  });
}
