import { AuditLogRepository } from '../repositories/audit.repository';
import { AuditLogEntity } from '../types';

export class AuditService {
  private auditRepo = new AuditLogRepository();

  async logAction(action: string, performedBy?: string, details?: string): Promise<AuditLogEntity> {
    const log: AuditLogEntity = {
      id: `log_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      action,
      performedBy: performedBy || 'SYSTEM',
      details,
      timestamp: new Date().toISOString(),
    };
    return await this.auditRepo.create(log);
  }

  async getLogs(): Promise<AuditLogEntity[]> {
    return await this.auditRepo.findAll();
  }
}
