import 'package:flutter_test/flutter_test.dart';
import 'package:amia_fest/services/scoring_service.dart';
import 'package:amia_fest/data/models/result_model.dart';
import 'package:amia_fest/data/models/team_model.dart';
import 'package:amia_fest/data/models/student_model.dart';
import 'package:amia_fest/core/constants/app_constants.dart';
import 'package:amia_fest/data/repositories/app_repositories.dart';

// Fake Repositories for Unit Testing without Native Plugins
class FakeResultRepository implements ResultRepository {
  final List<Result> _results = [];
  @override
  Future<List<Result>> getResults() async => _results;
  @override
  Future<List<Result>> getPublishedResults() async =>
      _results.where((r) => r.status == ResultStatus.published).toList();
  @override
  Future<List<Result>> getByProgram(String programId) async =>
      _results.where((r) => r.programId == programId).toList();
  @override
  Future<List<Result>> getByStudent(String studentId) async =>
      _results.where((r) => r.studentId == studentId).toList();
  @override
  Future<List<Result>> getByTeam(String teamId) async =>
      _results.where((r) => r.teamId == teamId).toList();
  @override
  Future<Result?> getById(String id) async =>
      _results.firstWhere((r) => r.id == id);
  @override
  Future<void> saveResult(Result result) async => _results.add(result);
  @override
  Future<void> updateResult(Result result) async {}
  @override
  Future<void> deleteResult(String id) async =>
      _results.removeWhere((r) => r.id == id);
}

class FakeTeamRepository implements TeamRepository {
  final List<Team> _teams = [
    Team(id: 't1', teamName: 'Alpha', teamCode: 'T1'),
    Team(id: 't2', teamName: 'Beta', teamCode: 'T2'),
  ];
  @override
  Future<List<Team>> getTeams() async => _teams;
  @override
  Future<Team?> getById(String id) async =>
      _teams.firstWhere((t) => t.id == id);
  @override
  Future<Team?> getByCode(String code) async =>
      _teams.firstWhere((t) => t.teamCode == code);
  @override
  Future<void> addTeam(Team team) async => _teams.add(team);
  @override
  Future<void> addTeams(List<Team> teams) async => _teams.addAll(teams);
  @override
  Future<void> updateTeam(Team team) async {}
  @override
  Future<void> deleteTeam(String id) async =>
      _teams.removeWhere((t) => t.id == id);
}

void main() {
  group('Scoring Service Calculations Unit Tests', () {
    late ScoringService scoringService;

    setUp(() {
      scoringService = ScoringService(
        resultRepository: FakeResultRepository(),
        teamRepository: FakeTeamRepository(),
      );
    });

    test('1st place with Grade A yields 10 points (5 + 5)', () {
      final points = scoringService.calculateResultPoints(
        position: 1,
        grade: 'A',
      );
      expect(points, equals(10));
    });

    test('2nd place with Grade B yields 6 points (3 + 3)', () {
      final points = scoringService.calculateResultPoints(
        position: 2,
        grade: 'B',
      );
      expect(points, equals(6));
    });

    test('3rd place with Grade C yields 2 points (1 + 1)', () {
      final points = scoringService.calculateResultPoints(
        position: 3,
        grade: 'C',
      );
      expect(points, equals(2));
    });

    test('Participant with Grade A yields 5 points', () {
      final points = scoringService.calculateResultPoints(
        position: null,
        grade: 'A',
      );
      expect(points, equals(5));
    });

    test('calculateTeamScoresFromResults updates team points by teamName or student fallback', () {
      final teams = [
        Team(id: 't1', teamName: 'Telos', teamCode: 'TE'),
        Team(id: 't2', teamName: 'Apex', teamCode: 'AP'),
      ];

      final publishedResults = [
        Result(
          id: 'r1',
          programId: 'p1',
          studentId: 's1',
          teamId: 'Telos', // Matched by teamName
          points: 10,
          status: ResultStatus.published,
        ),
        Result(
          id: 'r2',
          programId: 'p2',
          studentId: 's2',
          teamId: '', // Unmatched teamId, fallback to student teamId
          points: 6,
          status: ResultStatus.published,
        ),
      ];

      final students = <Student>[
        Student(
          id: 's2',
          chaseNumber: '102',
          name: 'Shahil',
          gender: 'Male',
          dateOfBirth: '2010-01-01',
          section: FestSection.subJunior,
          teamId: 'AP',
          phone: '1234567890',
          className: '10',
          schoolName: 'School',
        ),
      ];

      final updated = scoringService.calculateTeamScoresFromResults(teams, publishedResults, students);

      final telos = updated.firstWhere((t) => t.id == 't1');
      final apex = updated.firstWhere((t) => t.id == 't2');

      expect(telos.totalPoints, equals(10));
      expect(apex.totalPoints, equals(6));
      expect(telos.rank, equals(1));
      expect(apex.rank, equals(2));
    });

    test('Deleting all published results resets team scores to 0', () {
      final teams = <Team>[
        Team(id: 't1', teamName: 'Telos', teamCode: 'TL', totalPoints: 10, rank: 1),
        Team(id: 't2', teamName: 'Apex', teamCode: 'AP', totalPoints: 6, rank: 2),
      ];

      // Simulating all published results deleted (empty list)
      final List<Result> emptyPublishedResults = [];
      final resetTeams = scoringService.calculateTeamScoresFromResults(teams, emptyPublishedResults, []);

      expect(resetTeams.every((t) => t.totalPoints == 0), isTrue);
    });
  });
}
