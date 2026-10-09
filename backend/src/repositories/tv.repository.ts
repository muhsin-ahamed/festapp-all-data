import { supabase } from '../config/supabase';
import { TvSettingsEntity } from '../types';

export class TvSettingsRepository {
  private table = 'tv_settings';

  async getSettings(): Promise<TvSettingsEntity> {
    const { data, error } = await supabase.from(this.table).select('*').eq('id', 'default').maybeSingle();
    if (error && error.code !== 'PGRST116') throw error;
    if (data) return data;

    const defaultSettings: TvSettingsEntity = {
      id: 'default',
      scrollSpeed: 30,
      autoRefreshSeconds: 10,
      theme: 'dark',
      showTopTeamsCount: 5,
    };
    await this.updateSettings(defaultSettings);
    return defaultSettings;
  }

  async updateSettings(settings: Partial<TvSettingsEntity>): Promise<TvSettingsEntity> {
    const payload = { ...settings, id: 'default' };
    const { data, error } = await supabase.from(this.table).upsert([payload]).select().single();
    if (error) throw error;
    return data;
  }
}
