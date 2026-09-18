import '../core/constants/app_constants.dart';
import '../data/models/team_model.dart';
import '../data/models/result_model.dart';
import '../data/models/student_model.dart';
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
    double? marks,
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

    // Fallback based on raw marks if position and grade yielded no points
    if (total == 0 && marks != null && marks > 0) {
      if (marks >= 80) {
        total = customGradeA;
      } else if (marks >= 70) {
        total = customGradeB;
      } else if (marks >= 60) {
        total = customGradeC;
      } else {
        total = (marks / 10).round();
      }
    }

    return total;
  }

  List<Team> calculateTeamScoresFromResults(
    List<Team> teams,
    List<Result> publishedResults, [
    List<Student>? students,
  ]) {
    final Map<String, String> teamIdMap = {};
    for (var t in teams) {
      teamIdMap[t.id] = t.id;
      if (t.teamCode.isNotEmpty) {
        teamIdMap[t.teamCode.trim().toLowerCase()] = t.id;
      }
      if (t.teamName.isNotEmpty) {
        teamIdMap[t.teamName.trim().toLowerCase()] = t.id;
      }
    }

    final Map<String, String> studentToTeamMap = {};
    if (students != null) {
      for (var s in students) {
        if (s.teamId.isNotEmpty) {
          studentToTeamMap[s.id] = s.teamId;
        }
      }
    }

    final Map<String, int> teamScores = {for (var t in teams) t.id: 0};

    for (final res in publishedResults) {
      final key = res.teamId.trim().toLowerCase();
      var targetTeamId = teamIdMap[res.teamId] ?? teamIdMap[key];

      // Fallback: look up student's teamId if res.teamId was empty or unmatched
      if (targetTeamId == null && res.studentId.isNotEmpty) {
        final studTeamId = studentToTeamMap[res.studentId];
        if (studTeamId != null) {
          final studTeamKey = studTeamId.trim().toLowerCase();
          targetTeamId = teamIdMap[studTeamId] ?? teamIdMap[studTeamKey];
        }
      }

      if (targetTeamId != null && teamScores.containsKey(targetTeamId)) {
        teamScores[targetTeamId] = (teamScores[targetTeamId] ?? 0) + res.points;
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
      rankedTeams.add(ranked);
    }

    return rankedTeams;
  }

  Future<List<Team>> recalculateTeamScoresAndRanks({List<Student>? students}) async {
    final teams = await teamRepository.getTeams();
    final publishedResults = await resultRepository.getPublishedResults();

    final rankedTeams = calculateTeamScoresFromResults(teams, publishedResults, students);

    for (final ranked in rankedTeams) {
      try {
        await teamRepository.updateTeam(ranked);
      } catch (_) {}
    }

    return rankedTeams;
  }
}
