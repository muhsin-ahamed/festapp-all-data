import { TvSettingsRepository } from '../repositories/tv.repository';
import { AuditService } from './audit.service';
import { TvSettingsEntity } from '../types';

export class TvService {
  private tvRepo = new TvSettingsRepository();
  private auditService = new AuditService();

  async getSettings(): Promise<TvSettingsEntity> {
    return await this.tvRepo.getSettings();
  }

  async updateSettings(settings: Partial<TvSettingsEntity>, performedBy?: string): Promise<TvSettingsEntity> {
    const updated = await this.tvRepo.updateSettings(settings);
    await this.auditService.logAction('TV_SETTING_UPDATE', performedBy, 'Updated TV display settings');
    return updated;
  }
}
