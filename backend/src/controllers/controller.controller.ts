import { Request, Response, NextFunction } from 'express';
import { StudentService } from '../services/student.service';
import { TeamService } from '../services/team.service';
import { ProgramService } from '../services/program.service';
import { RegistrationService } from '../services/registration.service';
import { ResultService } from '../services/result.service';
import { JuryService } from '../services/jury.service';
import { ScheduleService } from '../services/schedule.service';
import { ExcelService } from '../services/excel.service';
import { AuditService } from '../services/audit.service';
import { TvService } from '../services/tv.service';
import { sendSuccess, sendError } from '../utils/apiResponse';
import { logger } from '../utils/logger';

const studentService = new StudentService();
const teamService = new TeamService();
const programService = new ProgramService();
const registrationService = new RegistrationService();
const resultService = new ResultService();
const juryService = new JuryService();
const scheduleService = new ScheduleService();
const excelService = new ExcelService();
const auditService = new AuditService();
const tvService = new TvService();

export async function getDashboard(req: Request, res: Response, next: NextFunction) {
  try {
    const students = await studentService.getStudents();
    const teams = await teamService.getTeams();
    const programs = await programService.getPrograms();
    const registrations = await registrationService.getRegistrations();
    const results = await resultService.getResults();
    const juries = await juryService.getJuries();

    const pendingResults = results.filter((r) => r.status === 'DRAFT' || r.status === 'SUBMITTED').length;
    const verifiedResults = results.filter((r) => r.status === 'VERIFIED').length;
    const publishedResults = results.filter((r) => r.status === 'PUBLISHED').length;

    return sendSuccess(
      res,
      {
        totalStudents: students.length,
        totalTeams: teams.length,
        totalPrograms: programs.length,
        totalRegistrations: registrations.length,
        pendingResults,
        verifiedResults,
        publishedResults,
        activeJuries: juries.filter((j) => j.status === 'ACTIVE').length,
        teamsSummary: teams.map((t) => ({ name: t.teamName, code: t.teamCode, points: t.totalPoints, rank: t.rank })),
      },
      'Controller dashboard overview'
    );
  } catch (error) {
    next(error);
  }
}

// Student Management
export async function getStudents(req: Request, res: Response, next: NextFunction) {
  try {
    const { teamId, section, query } = req.query;
    const students = await studentService.getStudents({
      teamId: teamId as string,
      section: section as string,
      query: query as string,
    });
    return sendSuccess(res, students, 'Students list');
  } catch (error) {
    next(error);
  }
}

export async function addStudent(req: Request, res: Response, next: NextFunction) {
  try {
    const created = await studentService.addStudent(req.body, req.user?.username);
    return sendSuccess(res, created, 'Student added successfully', 201);
  } catch (error) {
    next(error);
  }
}

export async function updateStudent(req: Request, res: Response, next: NextFunction) {
  try {
    const updated = await studentService.updateStudent(req.params.id, req.body, req.user?.username);
    return sendSuccess(res, updated, 'Student updated successfully');
  } catch (error) {
    next(error);
  }
}

export async function deleteStudent(req: Request, res: Response, next: NextFunction) {
  try {
    await studentService.deleteStudent(req.params.id, req.user?.username);
    return sendSuccess(res, {}, 'Student deleted successfully');
  } catch (error) {
    next(error);
  }
}

export async function importStudentsExcel(req: Request, res: Response, next: NextFunction) {
  try {
    const file = (req as any).file;
    if (!file && !req.body.buffer) {
      return sendError(res, 'Excel file upload required', 400, 'NO_FILE');
    }
    const fileBuffer = file?.buffer || Buffer.from(req.body.buffer, 'base64');
    const summary = await excelService.importStudentsFromBuffer(fileBuffer, req.user?.username);
    return sendSuccess(res, summary, 'Excel import completed');
  } catch (error) {
    next(error);
  }
}

export async function exportStudentsExcel(req: Request, res: Response, next: NextFunction) {
  try {
    const buffer = await excelService.exportStudentsToBuffer();
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', 'attachment; filename=students_export.xlsx');
    return res.send(buffer);
  } catch (error) {
    next(error);
  }
}

// Teams Management
export async function getTeams(req: Request, res: Response, next: NextFunction) {
  try {
    const section = req.query.section as string;
    const teams = await teamService.getTeams(section);
    return sendSuccess(res, teams, 'Teams list');
  } catch (error) {
    next(error);
  }
}

export async function addTeam(req: Request, res: Response, next: NextFunction) {
  try {
    const created = await teamService.addTeam(req.body, req.user?.username);
    return sendSuccess(res, created, 'Team created', 201);
  } catch (error) {
    next(error);
  }
}

export async function updateTeam(req: Request, res: Response, next: NextFunction) {
  logger.info(`[TEAM UPDATE REQUEST] Method: ${req.method} | URL: ${req.originalUrl} | ID: ${req.params.id}`, {
    body: req.body,
  });

  try {
    const teamId = req.params.id;
    if (!teamId || teamId.trim() === '') {
      logger.warn(`[TEAM UPDATE FAILED] Invalid team ID`, { teamId });
      return sendError(res, 'Invalid team data', 400, 'INVALID_TEAM_DATA');
    }

    const updated = await teamService.updateTeam(teamId, req.body, req.user?.username);
    logger.info(`[TEAM UPDATE SUCCESS] ID: ${teamId} | Status: 200`);
    return sendSuccess(res, updated, 'Team updated successfully', 200);
  } catch (error: any) {
    logger.error(`[TEAM UPDATE ERROR] ID: ${req.params.id} | Status: ${error.statusCode || 500}`, {
      message: error.message,
      details: error.details,
      hint: error.hint,
      code: error.code,
    });
    next(error);
  }
}

export async function deleteTeam(req: Request, res: Response, next: NextFunction) {
  try {
    await teamService.deleteTeam(req.params.id, req.user?.username);
    return sendSuccess(res, {}, 'Team deleted');
  } catch (error) {
    next(error);
  }
}

// Programs Management
export async function getPrograms(req: Request, res: Response, next: NextFunction) {
  try {
    const { section, category } = req.query;
    const programs = await programService.getPrograms({
      section: section as string,
      category: category as string,
    });
    return sendSuccess(res, programs, 'Programs list');
  } catch (error) {
    next(error);
  }
}

export async function addProgram(req: Request, res: Response, next: NextFunction) {
  try {
    const created = await programService.addProgram(req.body, req.user?.username);
    return sendSuccess(res, created, 'Program created', 201);
  } catch (error) {
    next(error);
  }
}

export async function updateProgram(req: Request, res: Response, next: NextFunction) {
  try {
    const updated = await programService.updateProgram(req.params.id, req.body, req.user?.username);
    return sendSuccess(res, updated, 'Program updated');
  } catch (error) {
    next(error);
  }
}

export async function deleteProgram(req: Request, res: Response, next: NextFunction) {
  try {
    await programService.deleteProgram(req.params.id, req.user?.username);
    return sendSuccess(res, {}, 'Program deleted');
  } catch (error) {
    next(error);
  }
}

// Results Workflow Management
export async function getResults(req: Request, res: Response, next: NextFunction) {
  try {
    const { programId, studentId, teamId, status, section } = req.query;
    const results = await resultService.getResults({
      programId: programId as string,
      studentId: studentId as string,
      teamId: teamId as string,
      status: status as string,
      section: section as string,
    });
    return sendSuccess(res, results, 'Results list');
  } catch (error) {
    next(error);
  }
}

export async function verifyResult(req: Request, res: Response, next: NextFunction) {
  try {
    const verified = await resultService.verifyResult(req.params.id, req.user?.username);
    return sendSuccess(res, verified, 'Result verified');
  } catch (error) {
    next(error);
  }
}

export async function publishResult(req: Request, res: Response, next: NextFunction) {
  try {
    const published = await resultService.publishResult(req.params.id, req.user?.username);
    return sendSuccess(res, published, 'Result published and team scores updated');
  } catch (error) {
    next(error);
  }
}

// Jury Management
export async function getJuries(req: Request, res: Response, next: NextFunction) {
  try {
    const juries = await juryService.getJuries();
    return sendSuccess(res, juries, 'Juries list');
  } catch (error) {
    next(error);
  }
}

export async function assignJuryProgram(req: Request, res: Response, next: NextFunction) {
  try {
    const { juryId, programId } = req.body;
    const updated = await juryService.assignProgram(juryId, programId, req.user?.username);
    return sendSuccess(res, updated, 'Program assigned to jury');
  } catch (error) {
    next(error);
  }
}

// Audit Logs
export async function getAuditLogs(req: Request, res: Response, next: NextFunction) {
  try {
    const logs = await auditService.getLogs();
    return sendSuccess(res, logs, 'System audit logs');
  } catch (error) {
    next(error);
  }
}
