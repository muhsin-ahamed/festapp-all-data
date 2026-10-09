import { supabase } from '../config/supabase';
import { AuditLogEntity } from '../types';

export class AuditLogRepository {
  private table = 'audit_logs';

  async findAll(): Promise<AuditLogEntity[]> {
    const { data, error } = await supabase.from(this.table).select('*').order('timestamp', { ascending: false });
    if (error) throw error;
    return data || [];
  }

  async create(log: AuditLogEntity): Promise<AuditLogEntity> {
    const { data, error } = await supabase.from(this.table).insert([log]).select().single();
    if (error) throw error;
    return data;
  }
}
