import { ScheduleRepository } from '../repositories/schedule.repository';
import { VenueRepository } from '../repositories/venue.repository';
import { AuditService } from './audit.service';
import { ScheduleEntity, VenueEntity } from '../types';

export class ScheduleService {
  private scheduleRepo = new ScheduleRepository();
  private venueRepo = new VenueRepository();
  private auditService = new AuditService();

  async getSchedules(): Promise<ScheduleEntity[]> {
    return await this.scheduleRepo.findAll();
  }

  async getVenues(): Promise<VenueEntity[]> {
    return await this.venueRepo.findAll();
  }

  async createSchedule(scheduleData: Omit<ScheduleEntity, 'id'>, performedBy?: string): Promise<ScheduleEntity> {
    const id = `sch_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const schedule: ScheduleEntity = {
      ...scheduleData,
      id,
      status: scheduleData.status || 'SCHEDULED',
    };

    const created = await this.scheduleRepo.create(schedule);
    await this.auditService.logAction('CREATE_SCHEDULE', performedBy, `Scheduled program ${schedule.programId}`);
    return created;
  }

  async createVenue(venueData: Omit<VenueEntity, 'id'>, performedBy?: string): Promise<VenueEntity> {
    const id = `vn_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const venue: VenueEntity = {
      ...venueData,
      id,
    };
    const created = await this.venueRepo.create(venue);
    await this.auditService.logAction('CREATE_VENUE', performedBy, `Created venue ${venue.name}`);
    return created;
  }
}
