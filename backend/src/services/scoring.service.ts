import { ResultRepository } from '../repositories/result.repository';
import { TeamRepository } from '../repositories/team.repository';
import { TeamEntity, ResultEntity } from '../types';

export class ScoringService {
  private resultRepo = new ResultRepository();
  private teamRepo = new TeamRepository();

  calculateResultPoints(position?: number, grade?: string): number {
    let total = 0;

    if (position === 1) total += 5;
    if (position === 2) total += 3;
    if (position === 3) total += 1;

    const cleanGrade = (grade || '').trim().toUpperCase();
    if (cleanGrade.includes('A')) total += 5;
    if (cleanGrade.includes('B')) total += 3;
    if (cleanGrade.includes('C')) total += 1;

    return total;
  }

  async recalculateTeamScoresAndRanks(): Promise<TeamEntity[]> {
    const teams = await this.teamRepo.findAll();
    const publishedResults = await this.resultRepo.findPublished();

    const teamScores: Record<string, number> = {};
    const teamIdMap: Record<string, string> = {};
    for (const t of teams) {
      teamScores[t.id] = 0;
      teamIdMap[t.id] = t.id;
      if (t.teamCode) {
        teamIdMap[t.teamCode.trim().toLowerCase()] = t.id;
      }
    }

    for (const res of publishedResults) {
      const key = (res.teamId || '').trim().toLowerCase();
      const targetTeamId = teamIdMap[res.teamId] || teamIdMap[key];
      if (targetTeamId && teamScores[targetTeamId] !== undefined) {
        teamScores[targetTeamId] += res.points || 0;
      }
    }

    // Map updated scores
    const updatedTeams: TeamEntity[] = teams.map((team) => ({
      ...team,
      totalPoints: teamScores[team.id] || 0,
    }));

    // Sort descending by points
    updatedTeams.sort((a, b) => (b.totalPoints || 0) - (a.totalPoints || 0));

    // Assign rank and update database
    const rankedTeams: TeamEntity[] = [];
    for (let i = 0; i < updatedTeams.length; i++) {
      const ranked: TeamEntity = {
        ...updatedTeams[i],
        rank: i + 1,
      };
      await this.teamRepo.update(ranked.id, { totalPoints: ranked.totalPoints, rank: ranked.rank });
      rankedTeams.push(ranked);
    }

    return rankedTeams;
  }

  async getLeaderboard(section?: string): Promise<any[]> {
    await this.recalculateTeamScoresAndRanks();
    const teams = await this.teamRepo.findAll(section);

    return teams.map((team, idx) => ({
      rank: idx + 1,
      team: team.teamName,
      teamCode: team.teamCode,
      points: team.totalPoints || 0,
      totalStudents: team.totalStudents || 0,
    }));
  }
}
