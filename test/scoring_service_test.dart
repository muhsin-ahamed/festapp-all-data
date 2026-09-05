import 'package:flutter_test/flutter_test.dart';
import 'package:amia_fest/services/scoring_service.dart';
import 'package:amia_fest/data/models/result_model.dart';
import 'package:amia_fest/data/models/team_model.dart';
import 'package:amia_fest/core/constants/app_constants.dart';
import 'package:amia_fest/data/repositories/app_repositories.dart';

// Fake Repositories for Unit Testing without Native Plugins
class FakeResultRepository implements ResultRepository {
  final List<Result> _results = [];
  @override
  Future<List<Result>> getResults() async => _results;
  @override
  Future<List<Result>> getPublishedResults() async => _results.where((r) => r.status == ResultStatus.published).toList();
  @override
  Future<List<Result>> getByProgram(String programId) async => _results.where((r) => r.programId == programId).toList();
  @override
  Future<List<Result>> getByStudent(String studentId) async => _results.where((r) => r.studentId == studentId).toList();
  @override
  Future<List<Result>> getByTeam(String teamId) async => _results.where((r) => r.teamId == teamId).toList();
  @override
  Future<Result?> getById(String id) async => _results.firstWhere((r) => r.id == id);
  @override
  Future<void> saveResult(Result result) async => _results.add(result);
  @override
  Future<void> updateResult(Result result) async {}
  @override
  Future<void> deleteResult(String id) async => _results.removeWhere((r) => r.id == id);
}

class FakeTeamRepository implements TeamRepository {
  final List<Team> _teams = [
    Team(id: 't1', teamName: 'Alpha', teamCode: 'T1'),
    Team(id: 't2', teamName: 'Beta', teamCode: 'T2'),
  ];
  @override
  Future<List<Team>> getTeams() async => _teams;
  @override
  Future<Team?> getById(String id) async => _teams.firstWhere((t) => t.id == id);
  @override
  Future<Team?> getByCode(String code) async => _teams.firstWhere((t) => t.teamCode == code);
  @override
  Future<void> addTeam(Team team) async => _teams.add(team);
  @override
  Future<void> addTeams(List<Team> teams) async => _teams.addAll(teams);
  @override
  Future<void> updateTeam(Team team) async {}
  @override
  Future<void> deleteTeam(String id) async => _teams.removeWhere((t) => t.id == id);
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

    test('1st place with Grade A yields 15 points (10 + 5)', () {
      final points = scoringService.calculateResultPoints(position: 1, grade: 'A');
      expect(points, equals(15));
    });

    test('2nd place with Grade B yields 10 points (7 + 3)', () {
      final points = scoringService.calculateResultPoints(position: 2, grade: 'B');
      expect(points, equals(10));
    });

    test('3rd place with Grade C yields 6 points (5 + 1)', () {
      final points = scoringService.calculateResultPoints(position: 3, grade: 'C');
      expect(points, equals(6));
    });

    test('Participant with Grade A yields 5 points', () {
      final points = scoringService.calculateResultPoints(position: null, grade: 'A');
      expect(points, equals(5));
    });
  });
}
