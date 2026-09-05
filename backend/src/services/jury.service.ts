import { JuryRepository } from '../repositories/jury.repository';
import { ProgramRepository } from '../repositories/program.repository';
import { StudentRepository } from '../repositories/student.repository';
import { RegistrationRepository } from '../repositories/registration.repository';
import { AuditService } from './audit.service';
import { JuryEntity, ProgramEntity, StudentEntity } from '../types';

export class JuryService {
  private juryRepo = new JuryRepository();
  private programRepo = new ProgramRepository();
  private studentRepo = new StudentRepository();
  private registrationRepo = new RegistrationRepository();
  private auditService = new AuditService();

  async getJuries(): Promise<JuryEntity[]> {
    return await this.juryRepo.findAll();
  }

  async getJuryById(id: string): Promise<JuryEntity | null> {
    return await this.juryRepo.findById(id);
  }

  async getAssignedPrograms(juryId: string): Promise<ProgramEntity[]> {
    const jury = await this.juryRepo.findById(juryId);
    if (!jury) return [];

    const assignedIds: string[] = jury.assignedPrograms || [];
    if (assignedIds.length === 0) return [];

    const programs: ProgramEntity[] = [];
    for (const pId of assignedIds) {
      const p = await this.programRepo.findById(pId);
      if (p) programs.push(p);
    }
    return programs;
  }

  async assignProgram(juryId: string, programId: string, performedBy?: string): Promise<JuryEntity> {
    const jury = await this.juryRepo.findById(juryId);
    if (!jury) throw { statusCode: 404, message: 'Jury not found', code: 'JURY_NOT_FOUND' };

    const program = await this.programRepo.findById(programId);
    if (!program) throw { statusCode: 404, message: 'Program not found', code: 'PROGRAM_NOT_FOUND' };

    const assigned = new Set(jury.assignedPrograms || []);
    assigned.add(programId);

    const updated = await this.juryRepo.update(juryId, {
      assignedPrograms: Array.from(assigned),
    });

    await this.auditService.logAction('ASSIGN_JURY_PROGRAM', performedBy, `Assigned program ${programId} to jury ${juryId}`);
    return updated;
  }

  async removeProgramAssignment(juryId: string, programId: string, performedBy?: string): Promise<JuryEntity> {
    const jury = await this.juryRepo.findById(juryId);
    if (!jury) throw { statusCode: 404, message: 'Jury not found', code: 'JURY_NOT_FOUND' };

    const assigned = (jury.assignedPrograms || []).filter((id) => id !== programId);
    const updated = await this.juryRepo.update(juryId, { assignedPrograms: assigned });

    await this.auditService.logAction('REMOVE_JURY_ASSIGNMENT', performedBy, `Removed program ${programId} from jury ${juryId}`);
    return updated;
  }

  async verifyScan(
    payload: string,
    juryId: string,
    userRole: string
  ): Promise<{ student: StudentEntity; registrations: any[]; assignedPrograms: ProgramEntity[] }> {
    const cleanPayload = payload.trim();
    let chaseNumber = cleanPayload;

    if (cleanPayload.startsWith('fest_program:')) {
      chaseNumber = cleanPayload.replace('fest_program:', '');
    } else if (cleanPayload.startsWith('fest_jury:')) {
      chaseNumber = cleanPayload.replace('fest_jury:', '');
    }

    // 1. Find Student by chase number or ID
    let student = await this.studentRepo.findByChaseNumber(chaseNumber);
    if (!student) {
      student = await this.studentRepo.findById(chaseNumber);
    }
    if (!student) {
      throw { statusCode: 404, message: 'Participant QR code not recognized.', code: 'STUDENT_NOT_FOUND' };
    }

    // 2. Fetch registrations for student
    const regs = await this.registrationRepo.findByStudent(student.id);

    // 3. Verify Jury program assignment
    let allowedPrograms: ProgramEntity[] = [];

    if (userRole === 'FEST_CONTROLLER') {
      // Controller can view all student registrations
      for (const r of regs) {
        const p = await this.programRepo.findById(r.programId);
        if (p) allowedPrograms.push(p);
      }
    } else {
      const jury = await this.juryRepo.findById(juryId);
      const assignedIds = new Set(jury?.assignedPrograms || []);

      for (const r of regs) {
        if (assignedIds.has(r.programId)) {
          const p = await this.programRepo.findById(r.programId);
          if (p) allowedPrograms.push(p);
        }
      }

      if (allowedPrograms.length === 0) {
        throw {
          statusCode: 403,
          message: 'Forbidden: Jury member is not assigned to any program registered by this participant.',
          code: 'JURY_NOT_ASSIGNED',
        };
      }
    }

    return {
      student,
      registrations: regs,
      assignedPrograms: allowedPrograms,
    };
  }
}
