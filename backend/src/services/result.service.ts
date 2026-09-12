import { ResultRepository } from '../repositories/result.repository';
import { ProgramRepository } from '../repositories/program.repository';
import { StudentRepository } from '../repositories/student.repository';
import { ScoringService } from './scoring.service';
import { AuditService } from './audit.service';
import { ResultEntity, ResultStatus } from '../types';

export class ResultService {
  private resultRepo = new ResultRepository();
  private programRepo = new ProgramRepository();
  private studentRepo = new StudentRepository();
  private scoringService = new ScoringService();
  private auditService = new AuditService();

  async getResults(filters?: { programId?: string; studentId?: string; teamId?: string; juryId?: string; status?: string; section?: string }): Promise<ResultEntity[]> {
    let results = await this.resultRepo.findAll(filters);

    if (filters?.section && filters.section !== 'ALL') {
      const filteredResults: ResultEntity[] = [];
      for (const res of results) {
        const prog = await this.programRepo.findById(res.programId);
        if (prog && prog.section.toUpperCase() === filters.section.toUpperCase()) {
          filteredResults.push(res);
        }
      }
      return filteredResults;
    }

    return results;
  }

  async getPublishedResults(section?: string): Promise<ResultEntity[]> {
    return await this.getResults({ status: 'PUBLISHED', section });
  }

  async getResultById(id: string): Promise<ResultEntity | null> {
    return await this.resultRepo.findById(id);
  }

  async submitJuryResult(
    programId: string,
    studentId: string,
    marks: number,
    grade?: string,
    position?: number,
    remarks?: string,
    juryId?: string,
    performedBy?: string,
    isDraft: boolean = false
  ): Promise<ResultEntity> {
    const student = await this.studentRepo.findById(studentId);
    if (!student) {
      throw { statusCode: 404, message: 'Student not found', code: 'STUDENT_NOT_FOUND' };
    }

    if (position && position > 0) {
      const allProgResults = await this.resultRepo.findAll({ programId });
      const duplicatePos = allProgResults.find(
        (r) => r.position === position && r.studentId !== studentId
      );
      if (duplicatePos) {
        throw {
          statusCode: 400,
          message: `Position ${position} is already assigned to another student in this program`,
          code: 'DUPLICATE_POSITION',
        };
      }
    }

    const calculatedPoints = this.scoringService.calculateResultPoints(position, grade);
    const existing = await this.resultRepo.findByProgramAndStudent(programId, studentId);

    const status: ResultStatus = isDraft ? 'DRAFT' : 'SUBMITTED';

    if (existing) {
      const updated = await this.resultRepo.update(existing.id, {
        marks,
        grade,
        position,
        points: calculatedPoints,
        remarks,
        juryId: juryId || existing.juryId,
        status,
        updatedAt: new Date().toISOString(),
      });
      await this.auditService.logAction('SUBMIT_RESULT', performedBy, `Updated result ${updated.id} to status ${status}`);
      return updated;
    } else {
      const resId = `res_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
      const newResult: ResultEntity = {
        id: resId,
        programId,
        studentId,
        teamId: student.teamId,
        juryId,
        marks,
        grade,
        position,
        points: calculatedPoints,
        remarks,
        status,
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };
      const created = await this.resultRepo.create(newResult);
      await this.auditService.logAction('SUBMIT_RESULT', performedBy, `Created result ${created.id} with status ${status}`);
      return created;
    }
  }

  async verifyResult(id: string, performedBy?: string): Promise<ResultEntity> {
    const existing = await this.resultRepo.findById(id);
    if (!existing) {
      throw { statusCode: 404, message: 'Result not found', code: 'RESULT_NOT_FOUND' };
    }

    const updated = await this.resultRepo.update(id, {
      status: 'VERIFIED',
      updatedAt: new Date().toISOString(),
    });

    await this.auditService.logAction('VERIFY_RESULT', performedBy, `Result ${id} marked as VERIFIED`);
    return updated;
  }

  async publishResult(id: string, performedBy?: string): Promise<ResultEntity> {
    const existing = await this.resultRepo.findById(id);
    if (!existing) {
      throw { statusCode: 404, message: 'Result not found', code: 'RESULT_NOT_FOUND' };
    }

    const updated = await this.resultRepo.update(id, {
      status: 'PUBLISHED',
      publishedAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    });

    // Re-calculate team points automatically
    await this.scoringService.recalculateTeamScoresAndRanks();
    await this.auditService.logAction('PUBLISH_RESULT', performedBy, `Result ${id} PUBLISHED`);

    return updated;
  }

  async deleteResult(id: string, performedBy?: string): Promise<void> {
    const existing = await this.resultRepo.findById(id);
    if (!existing) {
      throw { statusCode: 404, message: 'Result not found', code: 'RESULT_NOT_FOUND' };
    }

    await this.resultRepo.delete(id);
    await this.scoringService.recalculateTeamScoresAndRanks();
    await this.auditService.logAction('DELETE_RESULT', performedBy, `Result ${id} deleted`);
  }
}
