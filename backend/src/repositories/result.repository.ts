import { supabase } from '../config/supabase';
import { ResultEntity } from '../types';

export class ResultRepository {
  private table = 'results';

  async findAll(filters?: { programId?: string; studentId?: string; teamId?: string; juryId?: string; status?: string }): Promise<ResultEntity[]> {
    let queryBuilder = supabase.from(this.table).select('*');
    if (filters?.programId) {
      queryBuilder = queryBuilder.eq('programId', filters.programId);
    }
    if (filters?.studentId) {
      queryBuilder = queryBuilder.eq('studentId', filters.studentId);
    }
    if (filters?.teamId) {
      queryBuilder = queryBuilder.eq('teamId', filters.teamId);
    }
    if (filters?.juryId) {
      queryBuilder = queryBuilder.eq('juryId', filters.juryId);
    }
    if (filters?.status) {
      queryBuilder = queryBuilder.eq('status', filters.status);
    }

    const { data, error } = await queryBuilder;
    if (error) throw error;
    return data || [];
  }

  async findPublished(): Promise<ResultEntity[]> {
    const { data, error } = await supabase.from(this.table).select('*').eq('status', 'PUBLISHED');
    if (error) throw error;
    return data || [];
  }

  async findById(id: string): Promise<ResultEntity | null> {
    const { data, error } = await supabase.from(this.table).select('*').eq('id', id).maybeSingle();
    if (error) throw error;
    return data;
  }

  async findByProgramAndStudent(programId: string, studentId: string): Promise<ResultEntity | null> {
    const { data, error } = await supabase
      .from(this.table)
      .select('*')
      .eq('programId', programId)
      .eq('studentId', studentId)
      .maybeSingle();
    if (error) throw error;
    return data;
  }

  async create(result: ResultEntity): Promise<ResultEntity> {
    const { data, error } = await supabase.from(this.table).insert([result]).select().single();
    if (error) throw error;
    return data;
  }

  async upsert(result: ResultEntity): Promise<ResultEntity> {
    const { data, error } = await supabase.from(this.table).upsert([result]).select().single();
    if (error) throw error;
    return data;
  }

  async update(id: string, result: Partial<ResultEntity>): Promise<ResultEntity> {
    const { data, error } = await supabase.from(this.table).update(result).eq('id', id).select().single();
    if (error) throw error;
    return data;
  }

  async delete(id: string): Promise<void> {
    const { error } = await supabase.from(this.table).delete().eq('id', id);
    if (error) throw error;
  }
}
