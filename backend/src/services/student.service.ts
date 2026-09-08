import { StudentRepository } from '../repositories/student.repository';
import { TeamRepository } from '../repositories/team.repository';
import { AuditService } from './audit.service';
import { StudentEntity } from '../types';

export class StudentService {
  private studentRepo = new StudentRepository();
  private teamRepo = new TeamRepository();
  private auditService = new AuditService();

  async getStudents(filters?: { teamId?: string; section?: string; query?: string }): Promise<StudentEntity[]> {
    return await this.studentRepo.findAll(filters);
  }

  async getStudentById(id: string): Promise<StudentEntity | null> {
    return await this.studentRepo.findById(id);
  }

  async getStudentByChaseNumber(chaseNumber: string): Promise<StudentEntity | null> {
    return await this.studentRepo.findByChaseNumber(chaseNumber);
  }

  async addStudent(studentData: Omit<StudentEntity, 'id'>, performedBy?: string): Promise<StudentEntity> {
    // 1. Verify chase number uniqueness
    const existingChase = await this.studentRepo.findByChaseNumber(studentData.chaseNumber);
    if (existingChase) {
      throw { statusCode: 409, message: `Chase number '${studentData.chaseNumber}' is already registered.`, code: 'DUPLICATE_CHASE_NUMBER' };
    }

    // 2. Verify team exists
    const team = await this.teamRepo.findById(studentData.teamId);
    if (!team) {
      throw { statusCode: 404, message: 'Assigned team does not exist.', code: 'TEAM_NOT_FOUND' };
    }

    const id = (studentData as any).id && typeof (studentData as any).id === 'string' && (studentData as any).id.trim().length > 0
      ? (studentData as any).id.trim()
      : `std_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const student: StudentEntity = {
      ...studentData,
      id,
      qrCode: studentData.chaseNumber,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    const created = await this.studentRepo.create(student);
    await this.auditService.logAction('CREATE_STUDENT', performedBy, `Student ${student.name} (${student.chaseNumber}) created`);
    return created;
  }

  async updateStudent(id: string, studentData: Partial<StudentEntity>, performedBy?: string): Promise<StudentEntity> {
    const existing = await this.studentRepo.findById(id);
    if (!existing) {
      throw { statusCode: 404, message: 'Student not found', code: 'STUDENT_NOT_FOUND' };
    }

    if (studentData.chaseNumber && studentData.chaseNumber !== existing.chaseNumber) {
      const duplicate = await this.studentRepo.findByChaseNumber(studentData.chaseNumber);
      if (duplicate) {
        throw { statusCode: 409, message: `Chase number '${studentData.chaseNumber}' already exists`, code: 'DUPLICATE_CHASE_NUMBER' };
      }
    }

    const updated = await this.studentRepo.update(id, {
      ...studentData,
      updatedAt: new Date().toISOString(),
    });

    await this.auditService.logAction('UPDATE_STUDENT', performedBy, `Student ${id} updated`);
    return updated;
  }

  async deleteStudent(id: string, performedBy?: string): Promise<void> {
    const existing = await this.studentRepo.findById(id);
    if (!existing) {
      throw { statusCode: 404, message: 'Student not found', code: 'STUDENT_NOT_FOUND' };
    }

    await this.studentRepo.delete(id);
    await this.auditService.logAction('DELETE_STUDENT', performedBy, `Student ${existing.name} (${id}) deleted`);
  }
}
