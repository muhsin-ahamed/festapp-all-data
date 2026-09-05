import { supabase } from '../config/supabase';
import { ScheduleEntity } from '../types';

export class ScheduleRepository {
  private table = 'schedules';

  async findAll(): Promise<ScheduleEntity[]> {
    const { data, error } = await supabase.from(this.table).select('*');
    if (error) throw error;
    return data || [];
  }

  async findById(id: string): Promise<ScheduleEntity | null> {
    const { data, error } = await supabase.from(this.table).select('*').eq('id', id).maybeSingle();
    if (error) throw error;
    return data;
  }

  async create(schedule: ScheduleEntity): Promise<ScheduleEntity> {
    const { data, error } = await supabase.from(this.table).insert([schedule]).select().single();
    if (error) throw error;
    return data;
  }

  async update(id: string, schedule: Partial<ScheduleEntity>): Promise<ScheduleEntity> {
    const { data, error } = await supabase.from(this.table).update(schedule).eq('id', id).select().single();
    if (error) throw error;
    return data;
  }

  async delete(id: string): Promise<void> {
    const { error } = await supabase.from(this.table).delete().eq('id', id);
    if (error) throw error;
  }
}
