import '../core/constants/app_constants.dart';
import '../data/models/team_model.dart';
import '../data/repositories/app_repositories.dart';

class ScoringService {
  final ResultRepository resultRepository;
  final TeamRepository teamRepository;

  ScoringService({
    required this.resultRepository,
    required this.teamRepository,
  });

  int calculateResultPoints({
    int? position,
    String? grade,
    int customFirst = AppConstants.pointsFirst,
    int customSecond = AppConstants.pointsSecond,
    int customThird = AppConstants.pointsThird,
    int customGradeA = AppConstants.pointsGradeA,
    int customGradeB = AppConstants.pointsGradeB,
    int customGradeC = AppConstants.pointsGradeC,
  }) {
    int total = 0;

    // Position points
    if (position == 1) total += customFirst;
    if (position == 2) total += customSecond;
    if (position == 3) total += customThird;

    // Grade points
    final cleanGrade = (grade ?? '').trim().toUpperCase();
    if (cleanGrade.contains('A')) total += customGradeA;
    if (cleanGrade.contains('B')) total += customGradeB;
    if (cleanGrade.contains('C')) total += customGradeC;

    return total;
  }

  Future<List<Team>> recalculateTeamScoresAndRanks() async {
    final teams = await teamRepository.getTeams();
    final publishedResults = await resultRepository.getPublishedResults();

    final Map<String, int> teamScores = {for (var t in teams) t.id: 0};

    for (final res in publishedResults) {
      if (teamScores.containsKey(res.teamId)) {
        teamScores[res.teamId] = (teamScores[res.teamId] ?? 0) + res.points;
      }
    }

    // Update total points for teams
    List<Team> updatedTeams = teams.map((team) {
      return team.copyWith(totalPoints: teamScores[team.id] ?? 0);
    }).toList();

    // Sort by points descending
    updatedTeams.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

    // Assign rank
    List<Team> rankedTeams = [];
    for (int i = 0; i < updatedTeams.length; i++) {
      final ranked = updatedTeams[i].copyWith(rank: i + 1);
      await teamRepository.updateTeam(ranked);
      rankedTeams.add(ranked);
    }

    return rankedTeams;
  }
}
