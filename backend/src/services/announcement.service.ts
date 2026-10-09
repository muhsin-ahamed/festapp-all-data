import { AnnouncementRepository } from '../repositories/announcement.repository';
import { AuditService } from './audit.service';
import { AnnouncementEntity } from '../types';

export class AnnouncementService {
  private announcementRepo = new AnnouncementRepository();
  private auditService = new AuditService();

  async getAnnouncements(activeOnly: boolean = false): Promise<AnnouncementEntity[]> {
    return await this.announcementRepo.findAll(activeOnly);
  }

  async createAnnouncement(announcementData: Omit<AnnouncementEntity, 'id'>, performedBy?: string): Promise<AnnouncementEntity> {
    const id = `ann_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const announcement: AnnouncementEntity = {
      ...announcementData,
      id,
      status: announcementData.status || 'ANNOUNCED',
      createdAt: new Date().toISOString(),
      announcedAt: new Date().toISOString(),
    };

    const created = await this.announcementRepo.create(announcement);
    await this.auditService.logAction('ANNOUNCEMENT_CREATE', performedBy, `Created announcement: ${created.title}`);
    return created;
  }

  async updateAnnouncement(id: string, data: Partial<AnnouncementEntity>, performedBy?: string): Promise<AnnouncementEntity> {
    const updated = await this.announcementRepo.update(id, data);
    await this.auditService.logAction('ANNOUNCEMENT_UPDATE', performedBy, `Updated announcement ${id}`);
    return updated;
  }

  async deleteAnnouncement(id: string, performedBy?: string): Promise<void> {
    await this.announcementRepo.delete(id);
    await this.auditService.logAction('ANNOUNCEMENT_DELETE', performedBy, `Deleted announcement ${id}`);
  }
}
