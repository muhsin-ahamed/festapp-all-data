import { supabase } from '../config/supabase';
import { TeamEntity } from '../types';
import { logger } from '../utils/logger';

export class TeamRepository {
  private table = 'teams';

  async findAll(section?: string): Promise<TeamEntity[]> {
    let queryBuilder = supabase.from(this.table).select('*');
    if (section && section !== 'ALL') {
      queryBuilder = queryBuilder.eq('section', section);
    }
    const { data, error } = await queryBuilder.order('totalPoints', { ascending: false });
    if (error) throw error;
    return data || [];
  }

  async findById(id: string): Promise<TeamEntity | null> {
    const { data, error } = await supabase.from(this.table).select('*').eq('id', id).maybeSingle();
    if (error) throw error;
    return data;
  }

  async findByCode(teamCode: string): Promise<TeamEntity | null> {
    const { data, error } = await supabase.from(this.table).select('*').eq('teamCode', teamCode).maybeSingle();
    if (error) throw error;
    return data;
  }

  async findByName(teamName: string): Promise<TeamEntity | null> {
    const { data, error } = await supabase.from(this.table).select('*').eq('teamName', teamName).maybeSingle();
    if (error) throw error;
    return data;
  }

  async create(team: TeamEntity): Promise<TeamEntity> {
    const { data, error } = await supabase.from(this.table).insert([team]).select().single();
    if (error) throw error;
    return data;
  }

  async update(id: string, team: Partial<TeamEntity>): Promise<TeamEntity> {
    const updatePayload: Record<string, any> = {};

    if (team.teamName !== undefined) updatePayload.teamName = team.teamName;
    if (team.teamCode !== undefined) updatePayload.teamCode = team.teamCode;
    if (team.leaderName !== undefined) updatePayload.leaderName = team.leaderName;
    if (team.mentorName !== undefined) updatePayload.mentorName = team.mentorName;
    if (team.assistantLeaderName !== undefined) updatePayload.assistantLeaderName = team.assistantLeaderName;
    if (team.leaderId !== undefined) updatePayload.leaderId = team.leaderId;
    if (team.section !== undefined) updatePayload.section = team.section;
    if (team.logo !== undefined) updatePayload.logo = team.logo;
    if (team.status !== undefined) updatePayload.status = team.status;

    updatePayload.updatedAt = new Date().toISOString();

    const { data, error } = await supabase.from(this.table).update(updatePayload).eq('id', id).select().single();
    if (error) {
      logger.error(`[SUPABASE TEAM UPDATE ERROR] Team ID: ${id}`, {
        message: error.message,
        details: error.details,
        hint: error.hint,
        code: error.code,
      });
      throw error;
    }
    return data;
  }

  async delete(id: string): Promise<void> {
    const { error } = await supabase.from(this.table).delete().eq('id', id);
    if (error) throw error;
  }
}
