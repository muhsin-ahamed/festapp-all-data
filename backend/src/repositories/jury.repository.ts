import { supabase } from '../config/supabase';
import { JuryEntity } from '../types';

export class JuryRepository {
  private table = 'juries';

  async findAll(): Promise<JuryEntity[]> {
    const { data, error } = await supabase.from(this.table).select('*');
    if (error) throw error;
    return data || [];
  }

  async findById(id: string): Promise<JuryEntity | null> {
    const { data, error } = await supabase.from(this.table).select('*').eq('id', id).maybeSingle();
    if (error) throw error;
    return data;
  }

  async findByUsername(username: string): Promise<JuryEntity | null> {
    const { data, error } = await supabase.from(this.table).select('*').eq('username', username).maybeSingle();
    if (error) throw error;
    return data;
  }

  async create(jury: JuryEntity): Promise<JuryEntity> {
    const { data, error } = await supabase.from(this.table).insert([jury]).select().single();
    if (error) throw error;
    return data;
  }

  async update(id: string, jury: Partial<JuryEntity>): Promise<JuryEntity> {
    const { data, error } = await supabase.from(this.table).update(jury).eq('id', id).select().single();
    if (error) throw error;
    return data;
  }

  async delete(id: string): Promise<void> {
    const { error } = await supabase.from(this.table).delete().eq('id', id);
    if (error) throw error;
  }
}
