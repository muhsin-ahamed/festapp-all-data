import { TeamRepository } from '../repositories/team.repository';
import { AuditService } from './audit.service';
import { TeamEntity } from '../types';

export class TeamService {
  private teamRepo = new TeamRepository();
  private auditService = new AuditService();

  async getTeams(section?: string): Promise<TeamEntity[]> {
    return await this.teamRepo.findAll(section);
  }

  async getTeamById(id: string): Promise<TeamEntity | null> {
    return await this.teamRepo.findById(id);
  }

  async addTeam(teamData: Omit<TeamEntity, 'id'>, performedBy?: string): Promise<TeamEntity> {
    const existingCode = await this.teamRepo.findByCode(teamData.teamCode);
    if (existingCode) {
      throw { statusCode: 409, message: `Team code '${teamData.teamCode}' is already in use`, code: 'DUPLICATE_TEAM_CODE' };
    }

    const id = `team_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const team: TeamEntity = {
      ...teamData,
      id,
      totalPoints: 0,
      totalStudents: 0,
      rank: 0,
      status: 'ACTIVE',
      createdAt: new Date().toISOString(),
    };

    const created = await this.teamRepo.create(team);
    await this.auditService.logAction('CREATE_TEAM', performedBy, `Team ${team.teamName} (${team.teamCode}) created`);
    return created;
  }

  async updateTeam(id: string, teamData: Partial<TeamEntity>, performedBy?: string): Promise<TeamEntity> {
    const existing = await this.teamRepo.findById(id);
    if (!existing) {
      throw { statusCode: 404, message: 'Team not found', code: 'TEAM_NOT_FOUND' };
    }

    if (teamData.teamCode && teamData.teamCode !== existing.teamCode) {
      const duplicateCode = await this.teamRepo.findByCode(teamData.teamCode);
      if (duplicateCode && duplicateCode.id !== id) {
        throw { statusCode: 409, message: 'Team name or team code already exists', code: 'DUPLICATE_TEAM_CODE' };
      }
    }

    if (teamData.teamName && teamData.teamName !== existing.teamName) {
      const duplicateName = await this.teamRepo.findByName(teamData.teamName);
      if (duplicateName && duplicateName.id !== id) {
        throw { statusCode: 409, message: 'Team name or team code already exists', code: 'DUPLICATE_TEAM_NAME' };
      }
    }

    const updated = await this.teamRepo.update(id, teamData);
    await this.auditService.logAction('UPDATE_TEAM', performedBy, `Team ${id} updated`);
    return updated;
  }

  async deleteTeam(id: string, performedBy?: string): Promise<void> {
    const existing = await this.teamRepo.findById(id);
    if (!existing) {
      throw { statusCode: 404, message: 'Team not found', code: 'TEAM_NOT_FOUND' };
    }

    await this.teamRepo.delete(id);
    await this.auditService.logAction('DELETE_TEAM', performedBy, `Team ${existing.teamName} deleted`);
  }
}
