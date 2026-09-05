import { ProgramRepository } from '../repositories/program.repository';
import { AuditService } from './audit.service';
import { ProgramEntity } from '../types';

export class ProgramService {
  private programRepo = new ProgramRepository();
  private auditService = new AuditService();

  async getPrograms(filters?: { section?: string; category?: string }): Promise<ProgramEntity[]> {
    console.log('[Node.js API] GET programs request with filters:', filters);
    const list = await this.programRepo.findAll(filters);
    console.log(`[Node.js API] Supabase SELECT result count: ${list.length}`);
    return list;
  }

  async getProgramById(id: string): Promise<ProgramEntity | null> {
    return await this.programRepo.findById(id);
  }

  async addProgram(programData: any, performedBy?: string): Promise<ProgramEntity> {
    console.log('[Node.js API] Received create-program request:', programData);

    const code = (programData.programCode || programData.program_code || '').toString().trim();
    if (!code) {
      throw { statusCode: 400, message: 'Program code is required', code: 'MISSING_PROGRAM_CODE' };
    }

    const name = (programData.programName || programData.program_name || '').toString().trim();
    if (!name) {
      throw { statusCode: 400, message: 'Program name is required', code: 'MISSING_PROGRAM_NAME' };
    }

    const existingCode = await this.programRepo.findByCode(code);
    if (existingCode) {
      throw { statusCode: 409, message: `Program code '${code}' already exists`, code: 'DUPLICATE_PROGRAM_CODE' };
    }

    const id = programData.id && typeof programData.id === 'string' && programData.id.startsWith('prog_')
      ? programData.id
      : `prog_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;

    // Sanitize payload strictly to match the 11 columns in public.programs
    const program: ProgramEntity = {
      id,
      programCode: code,
      programName: name,
      section: (programData.section && programData.section.toString().toLowerCase() !== 'junior') ? programData.section.toString() : 'subJunior',
      category: (programData.category || 'stage').toString(),
      isStageProgram: programData.isStageProgram !== undefined ? Boolean(programData.isStageProgram) : true,
      isGeneral: programData.isGeneral !== undefined ? Boolean(programData.isGeneral) : false,
      duration: (programData.duration || '30 mins').toString(),
      venueId: programData.venueId || programData.venue_id || null,
      scheduleId: programData.scheduleId || programData.schedule_id || null,
      status: (programData.status || 'UPCOMING').toString(),
    };

    console.log('[Node.js API] Sanitized program payload for Supabase:', program);
    const created = await this.programRepo.create(program);
    console.log('[Node.js API] Supabase INSERT result success:', created);
    await this.auditService.logAction('CREATE_PROGRAM', performedBy, `Program ${program.programName} (${program.programCode}) created`);
    return created;
  }

  async updateProgram(id: string, programData: Partial<ProgramEntity>, performedBy?: string): Promise<ProgramEntity> {
    console.log('[Node.js API] Received update-program request for id:', id, programData);
    const existing = await this.programRepo.findById(id);
    if (!existing) {
      throw { statusCode: 404, message: 'Program not found', code: 'PROGRAM_NOT_FOUND' };
    }

    if (programData.programCode && programData.programCode !== existing.programCode) {
      const duplicate = await this.programRepo.findByCode(programData.programCode);
      if (duplicate) {
        throw { statusCode: 409, message: `Program code '${programData.programCode}' already exists`, code: 'DUPLICATE_PROGRAM_CODE' };
      }
    }

    // Sanitize payload strictly to match the 11 columns in public.programs
    const updatePayload: Partial<ProgramEntity> = {};
    if (programData.programCode !== undefined) updatePayload.programCode = programData.programCode;
    if (programData.programName !== undefined) updatePayload.programName = programData.programName;
    if (programData.section !== undefined) updatePayload.section = programData.section;
    if (programData.category !== undefined) updatePayload.category = programData.category;
    if (programData.isStageProgram !== undefined) updatePayload.isStageProgram = Boolean(programData.isStageProgram);
    if (programData.isGeneral !== undefined) updatePayload.isGeneral = Boolean(programData.isGeneral);
    if (programData.duration !== undefined) updatePayload.duration = programData.duration;
    if (programData.venueId !== undefined) updatePayload.venueId = programData.venueId;
    if (programData.scheduleId !== undefined) updatePayload.scheduleId = programData.scheduleId;
    if (programData.status !== undefined) updatePayload.status = programData.status;

    const updated = await this.programRepo.update(id, updatePayload);
    console.log('[Node.js API] Supabase UPDATE result success:', updated);
    await this.auditService.logAction('UPDATE_PROGRAM', performedBy, `Program ${id} updated`);
    return updated;
  }

  async deleteProgram(id: string, performedBy?: string): Promise<void> {
    const existing = await this.programRepo.findById(id);
    if (!existing) {
      throw { statusCode: 404, message: 'Program not found', code: 'PROGRAM_NOT_FOUND' };
    }

    await this.programRepo.delete(id);
    await this.auditService.logAction('DELETE_PROGRAM', performedBy, `Program ${existing.programName} deleted`);
  }
}
