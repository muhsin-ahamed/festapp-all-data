import { Request, Response, NextFunction } from 'express';
import { StudentService } from '../services/student.service';
import { TeamService } from '../services/team.service';
import { ProgramService } from '../services/program.service';
import { RegistrationService } from '../services/registration.service';
import { ResultService } from '../services/result.service';
import { ScoringService } from '../services/scoring.service';
import { sendSuccess, sendError } from '../utils/apiResponse';

import { ExcelService } from '../services/excel.service';

const studentService = new StudentService();
const teamService = new TeamService();
const programService = new ProgramService();
const registrationService = new RegistrationService();
const resultService = new ResultService();
const scoringService = new ScoringService();
const excelService = new ExcelService();

export async function getLeaderDashboard(req: Request, res: Response, next: NextFunction) {
  try {
    const teamId = req.user?.teamId;
    if (!teamId) return sendError(res, 'No team assigned to leader', 403, 'NO_TEAM_ASSIGNED');

    const team = await teamService.getTeamById(teamId);
    const students = await studentService.getStudents({ teamId });
    const registrations = await registrationService.getRegistrations({ teamId });
    const results = await resultService.getResults({ teamId });

    return sendSuccess(
      res,
      {
        team,
        totalStudents: students.length,
        totalRegistrations: registrations.length,
        teamPoints: team?.totalPoints || 0,
        rank: team?.rank || 0,
        recentResults: results.slice(0, 5),
      },
      'Team leader dashboard summary'
    );
  } catch (error) {
    next(error);
  }
}

export async function getLeaderTeam(req: Request, res: Response, next: NextFunction) {
  try {
    const teamId = req.user?.teamId;
    if (!teamId) return sendError(res, 'No team assigned', 403, 'NO_TEAM_ASSIGNED');

    const team = await teamService.getTeamById(teamId);
    return sendSuccess(res, team, 'Team information');
  } catch (error) {
    next(error);
  }
}

export async function getLeaderStudents(req: Request, res: Response, next: NextFunction) {
  try {
    const teamId = req.user?.teamId;
    if (!teamId) return sendError(res, 'No team assigned', 403, 'NO_TEAM_ASSIGNED');

    const section = req.query.section as string;
    const students = await studentService.getStudents({ teamId, section });
    return sendSuccess(res, students, 'Team students list');
  } catch (error) {
    next(error);
  }
}

export async function addLeaderStudent(req: Request, res: Response, next: NextFunction) {
  try {
    const teamId = req.user?.teamId;
    if (!teamId) return sendError(res, 'No team assigned', 403, 'NO_TEAM_ASSIGNED');

    const studentData = { ...req.body, teamId };
    const created = await studentService.addStudent(studentData, req.user?.username);
    return sendSuccess(res, created, 'Student added to team', 201);
  } catch (error) {
    next(error);
  }
}

export async function updateLeaderStudent(req: Request, res: Response, next: NextFunction) {
  try {
    const teamId = req.user?.teamId;
    if (!teamId) return sendError(res, 'No team assigned', 403, 'NO_TEAM_ASSIGNED');

    const studentId = req.params.id;
    const existing = await studentService.getStudentById(studentId);
    if (!existing || existing.teamId !== teamId) {
      return sendError(res, 'Forbidden: Cannot edit student of another team', 403, 'CROSS_TEAM_FORBIDDEN');
    }

    const updated = await studentService.updateStudent(studentId, req.body, req.user?.username);
    return sendSuccess(res, updated, 'Student details updated');
  } catch (error) {
    next(error);
  }
}

export async function getLeaderPrograms(req: Request, res: Response, next: NextFunction) {
  try {
    const section = req.query.section as string;
    const programs = await programService.getPrograms({ section });
    return sendSuccess(res, programs, 'Available programs for section');
  } catch (error) {
    next(error);
  }
}

export async function createLeaderRegistration(req: Request, res: Response, next: NextFunction) {
  try {
    const teamId = req.user?.teamId;
    if (!teamId) return sendError(res, 'No team assigned', 403, 'NO_TEAM_ASSIGNED');

    const { studentId, programId } = req.body;
    const created = await registrationService.createRegistration(studentId, programId, teamId, req.user?.username);
    return sendSuccess(res, created, 'Student registered successfully for program', 201);
  } catch (error) {
    next(error);
  }
}

export async function getLeaderRegistrations(req: Request, res: Response, next: NextFunction) {
  try {
    const teamId = req.user?.teamId;
    if (!teamId) return sendError(res, 'No team assigned', 403, 'NO_TEAM_ASSIGNED');

    const registrations = await registrationService.getRegistrations({ teamId });
    return sendSuccess(res, registrations, 'Team registrations');
  } catch (error) {
    next(error);
  }
}

export async function getLeaderResults(req: Request, res: Response, next: NextFunction) {
  try {
    const teamId = req.user?.teamId;
    if (!teamId) return sendError(res, 'No team assigned', 403, 'NO_TEAM_ASSIGNED');

    const results = await resultService.getResults({ teamId });
    return sendSuccess(res, results, 'Team results');
  } catch (error) {
    next(error);
  }
}

export async function importLeaderStudentsExcel(req: Request, res: Response, next: NextFunction) {
  try {
    const teamId = req.user?.teamId;
    if (!teamId) return sendError(res, 'No team assigned to leader', 403, 'NO_TEAM_ASSIGNED');

    const file = (req as any).file;
    if (!file && !req.body.buffer) {
      return sendError(res, 'Excel file upload required', 400, 'NO_FILE');
    }
    const fileBuffer = file?.buffer || Buffer.from(req.body.buffer, 'base64');
    const summary = await excelService.importStudentsFromBuffer(fileBuffer, req.user?.username);
    return sendSuccess(res, summary, 'Team Excel student import completed');
  } catch (error) {
    next(error);
  }
}

