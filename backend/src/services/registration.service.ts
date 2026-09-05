import { RegistrationRepository } from '../repositories/registration.repository';
import { StudentRepository } from '../repositories/student.repository';
import { ProgramRepository } from '../repositories/program.repository';
import { AuditService } from './audit.service';
import { RegistrationEntity } from '../types';

export class RegistrationService {
  private registrationRepo = new RegistrationRepository();
  private studentRepo = new StudentRepository();
  private programRepo = new ProgramRepository();
  private auditService = new AuditService();

  async getRegistrations(filters?: { teamId?: string; studentId?: string; programId?: string; status?: string }): Promise<RegistrationEntity[]> {
    return await this.registrationRepo.findAll(filters);
  }

  async createRegistration(
    studentId: string,
    programId: string,
    leaderTeamId?: string,
    performedBy?: string
  ): Promise<RegistrationEntity> {
    // 1. Fetch Student
    const student = await this.studentRepo.findById(studentId);
    if (!student) {
      throw { statusCode: 404, message: 'Student not found', code: 'STUDENT_NOT_FOUND' };
    }

    // 2. Verify Team Authorization for Team Leaders
    if (leaderTeamId && student.teamId !== leaderTeamId) {
      throw { statusCode: 403, message: 'Forbidden: You cannot register a student from another team.', code: 'CROSS_TEAM_FORBIDDEN' };
    }

    // 3. Fetch Program
    const program = await this.programRepo.findById(programId);
    if (!program) {
      throw { statusCode: 404, message: 'Program not found', code: 'PROGRAM_NOT_FOUND' };
    }

    // 4. Verify Section Compatibility
    if (program.section.toUpperCase() !== 'GENERAL' && student.section.toUpperCase() !== program.section.toUpperCase()) {
      throw {
        statusCode: 422,
        message: `Section mismatch: Student section '${student.section}' cannot register for '${program.section}' program.`,
        code: 'SECTION_MISMATCH',
      };
    }

    // 5. Check Duplicate Registration
    const existingReg = await this.registrationRepo.findByStudentAndProgram(studentId, programId);
    if (existingReg) {
      throw { statusCode: 409, message: 'Student is already registered for this program.', code: 'DUPLICATE_REGISTRATION' };
    }

    // 6. Check Registration Limits
    const studentRegistrations = await this.registrationRepo.findByStudent(studentId);
    const existingProgramIds = studentRegistrations.map((r) => r.programId);

    let stageCount = 0;
    let nonStageCount = 0;

    for (const pId of existingProgramIds) {
      const p = await this.programRepo.findById(pId);
      if (p) {
        if (p.isStageProgram || p.category?.toLowerCase().includes('stage')) {
          stageCount++;
        } else {
          nonStageCount++;
        }
      }
    }

    const isNewStage = program.isStageProgram || program.category?.toLowerCase().includes('stage');

    if (isNewStage && stageCount >= 6) {
      throw {
        statusCode: 422,
        message: 'Student has reached the maximum limit of 6 stage programs.',
        code: 'STAGE_LIMIT_EXCEEDED',
      };
    }

    if (!isNewStage && nonStageCount >= 4) {
      throw {
        statusCode: 422,
        message: 'Student has reached the maximum limit of 4 non-stage programs.',
        code: 'NON_STAGE_LIMIT_EXCEEDED',
      };
    }

    // 7. Create Registration
    const regId = `reg_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const regNumber = `REG-${Date.now().toString().slice(-6)}`;

    const registration: RegistrationEntity = {
      id: regId,
      studentId: student.id,
      programId: program.id,
      teamId: student.teamId,
      registrationNumber: regNumber,
      status: 'APPROVED',
      createdAt: new Date().toISOString(),
    };

    const created = await this.registrationRepo.create(registration);
    await this.auditService.logAction(
      'CREATE_REGISTRATION',
      performedBy,
      `Registered ${student.name} (${student.chaseNumber}) for program ${program.programName}`
    );

    return created;
  }

  async deleteRegistration(id: string, leaderTeamId?: string, performedBy?: string): Promise<void> {
    const existing = await this.registrationRepo.findById(id);
    if (!existing) {
      throw { statusCode: 404, message: 'Registration not found', code: 'REGISTRATION_NOT_FOUND' };
    }

    if (leaderTeamId && existing.teamId !== leaderTeamId) {
      throw { statusCode: 403, message: 'Forbidden: Cannot delete registration for another team', code: 'CROSS_TEAM_FORBIDDEN' };
    }

    await this.registrationRepo.delete(id);
    await this.auditService.logAction('DELETE_REGISTRATION', performedBy, `Deleted registration ${id}`);
  }
}
