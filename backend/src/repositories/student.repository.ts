import { supabase } from '../config/supabase';
import { StudentEntity } from '../types';

export class StudentRepository {
  private table = 'students';

  async findAll(filters?: { teamId?: string; section?: string; query?: string }): Promise<StudentEntity[]> {
    let queryBuilder = supabase.from(this.table).select('*');

    if (filters?.teamId) {
      queryBuilder = queryBuilder.eq('teamId', filters.teamId);
    }
    if (filters?.section) {
      queryBuilder = queryBuilder.eq('section', filters.section);
    }
    if (filters?.query) {
      const q = filters.query;
      queryBuilder = queryBuilder.or(`name.ilike.%${q}%,chaseNumber.ilike.%${q}%`);
    }

    const { data, error } = await queryBuilder;
    if (error) throw error;
    return data || [];
  }

  async findById(id: string): Promise<StudentEntity | null> {
    const { data, error } = await supabase.from(this.table).select('*').eq('id', id).maybeSingle();
    if (error) throw error;
    return data;
  }

  async findByChaseNumber(chaseNumber: string): Promise<StudentEntity | null> {
    const { data, error } = await supabase.from(this.table).select('*').eq('chaseNumber', chaseNumber).maybeSingle();
    if (error) throw error;
    return data;
  }

  async findByTeam(teamId: string): Promise<StudentEntity[]> {
    const { data, error } = await supabase.from(this.table).select('*').eq('teamId', teamId);
    if (error) throw error;
    return data || [];
  }

  async create(student: StudentEntity): Promise<StudentEntity> {
    const { data, error } = await supabase.from(this.table).insert([student]).select().single();
    if (error) throw error;
    return data;
  }

  async createBatch(students: StudentEntity[]): Promise<StudentEntity[]> {
    if (!students || students.length === 0) return [];
    const { data, error } = await supabase.from(this.table).insert(students).select();
    if (error) throw error;
    return data || [];
  }

  async update(id: string, student: Partial<StudentEntity>): Promise<StudentEntity> {
    const { data, error } = await supabase.from(this.table).update(student).eq('id', id).select().single();
    if (error) throw error;
    return data;
  }

  async delete(id: string): Promise<void> {
    const { error } = await supabase.from(this.table).delete().eq('id', id);
    if (error) throw error;
  }
}
