import { supabase } from '../config/supabase';
import { RegistrationEntity } from '../types';

export class RegistrationRepository {
  private table = 'registrations';

  async findAll(filters?: { teamId?: string; studentId?: string; programId?: string; status?: string }): Promise<RegistrationEntity[]> {
    let queryBuilder = supabase.from(this.table).select('*');
    if (filters?.teamId) {
      queryBuilder = queryBuilder.eq('teamId', filters.teamId);
    }
    if (filters?.studentId) {
      queryBuilder = queryBuilder.eq('studentId', filters.studentId);
    }
    if (filters?.programId) {
      queryBuilder = queryBuilder.eq('programId', filters.programId);
    }
    if (filters?.status) {
      queryBuilder = queryBuilder.eq('status', filters.status);
    }

    const { data, error } = await queryBuilder;
    if (error) throw error;
    return data || [];
  }

  async findById(id: string): Promise<RegistrationEntity | null> {
    const { data, error } = await supabase.from(this.table).select('*').eq('id', id).maybeSingle();
    if (error) throw error;
    return data;
  }

  async findByStudentAndProgram(studentId: string, programId: string): Promise<RegistrationEntity | null> {
    const { data, error } = await supabase
      .from(this.table)
      .select('*')
      .eq('studentId', studentId)
      .eq('programId', programId)
      .maybeSingle();
    if (error) throw error;
    return data;
  }

  async findByStudent(studentId: string): Promise<RegistrationEntity[]> {
    const { data, error } = await supabase.from(this.table).select('*').eq('studentId', studentId);
    if (error) throw error;
    return data || [];
  }

  async create(registration: RegistrationEntity): Promise<RegistrationEntity> {
    const { data, error } = await supabase.from(this.table).insert([registration]).select().single();
    if (error) throw error;
    return data;
  }

  async update(id: string, registration: Partial<RegistrationEntity>): Promise<RegistrationEntity> {
    const { data, error } = await supabase.from(this.table).update(registration).eq('id', id).select().single();
    if (error) throw error;
    return data;
  }

  async delete(id: string): Promise<void> {
    const { error } = await supabase.from(this.table).delete().eq('id', id);
    if (error) throw error;
  }
}
