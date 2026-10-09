import { supabase } from '../config/supabase';
import { ProgramEntity } from '../types';

export class ProgramRepository {
  private table = 'programs';

  async findAll(filters?: { section?: string; category?: string }): Promise<ProgramEntity[]> {
    let queryBuilder = supabase.from(this.table).select('*');
    if (filters?.section && filters.section !== 'ALL') {
      queryBuilder = queryBuilder.eq('section', filters.section);
    }
    if (filters?.category) {
      queryBuilder = queryBuilder.eq('category', filters.category);
    }
    const { data, error } = await queryBuilder;
    if (error) throw error;
    return data || [];
  }

  async findById(id: string): Promise<ProgramEntity | null> {
    const { data, error } = await supabase.from(this.table).select('*').eq('id', id).maybeSingle();
    if (error) throw error;
    return data;
  }

  async findByCode(programCode: string): Promise<ProgramEntity | null> {
    const { data, error } = await supabase.from(this.table).select('*').eq('programCode', programCode).maybeSingle();
    if (error) throw error;
    return data;
  }

  async create(program: ProgramEntity): Promise<ProgramEntity> {
    const { data, error } = await supabase.from(this.table).insert([program]).select().single();
    if (error) {
      console.error('[Node.js ProgramRepository] Supabase INSERT error:', error);
      throw error;
    }
    return data;
  }

  async update(id: string, program: Partial<ProgramEntity>): Promise<ProgramEntity> {
    const { data, error } = await supabase.from(this.table).update(program).eq('id', id).select().single();
    if (error) {
      console.error('[Node.js ProgramRepository] Supabase UPDATE error:', error);
      throw error;
    }
    return data;
  }

  async delete(id: string): Promise<void> {
    const { error } = await supabase.from(this.table).delete().eq('id', id);
    if (error) {
      console.error('[Node.js ProgramRepository] Supabase DELETE error:', error);
      throw error;
    }
  }
}
