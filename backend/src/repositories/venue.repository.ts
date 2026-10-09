import { supabase } from '../config/supabase';
import { VenueEntity } from '../types';

export class VenueRepository {
  private table = 'venues';

  async findAll(): Promise<VenueEntity[]> {
    const { data, error } = await supabase.from(this.table).select('*');
    if (error) throw error;
    return data || [];
  }

  async findById(id: string): Promise<VenueEntity | null> {
    const { data, error } = await supabase.from(this.table).select('*').eq('id', id).maybeSingle();
    if (error) throw error;
    return data;
  }

  async create(venue: VenueEntity): Promise<VenueEntity> {
    const { data, error } = await supabase.from(this.table).insert([venue]).select().single();
    if (error) throw error;
    return data;
  }

  async update(id: string, venue: Partial<VenueEntity>): Promise<VenueEntity> {
    const { data, error } = await supabase.from(this.table).update(venue).eq('id', id).select().single();
    if (error) throw error;
    return data;
  }

  async delete(id: string): Promise<void> {
    const { error } = await supabase.from(this.table).delete().eq('id', id);
    if (error) throw error;
  }
}
