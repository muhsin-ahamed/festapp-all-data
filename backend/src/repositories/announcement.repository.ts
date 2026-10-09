import { supabase } from '../config/supabase';
import { AnnouncementEntity } from '../types';

export class AnnouncementRepository {
  private table = 'announcements';

  async findAll(activeOnly: boolean = false): Promise<AnnouncementEntity[]> {
    let queryBuilder = supabase.from(this.table).select('*');
    if (activeOnly) {
      queryBuilder = queryBuilder.eq('status', 'ANNOUNCED');
    }
    const { data, error } = await queryBuilder.order('createdAt', { ascending: false });
    if (error) throw error;
    return data || [];
  }

  async findById(id: string): Promise<AnnouncementEntity | null> {
    const { data, error } = await supabase.from(this.table).select('*').eq('id', id).maybeSingle();
    if (error) throw error;
    return data;
  }

  async create(announcement: AnnouncementEntity): Promise<AnnouncementEntity> {
    const { data, error } = await supabase.from(this.table).insert([announcement]).select().single();
    if (error) throw error;
    return data;
  }

  async update(id: string, announcement: Partial<AnnouncementEntity>): Promise<AnnouncementEntity> {
    const { data, error } = await supabase.from(this.table).update(announcement).eq('id', id).select().single();
    if (error) throw error;
    return data;
  }

  async delete(id: string): Promise<void> {
    const { error } = await supabase.from(this.table).delete().eq('id', id);
    if (error) throw error;
  }
}
