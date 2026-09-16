import { Request, Response, NextFunction } from 'express';
import { TeamService } from '../services/team.service';
import { ScoringService } from '../services/scoring.service';
import { ProgramService } from '../services/program.service';
import { ScheduleService } from '../services/schedule.service';
import { ResultService } from '../services/result.service';
import { AnnouncementService } from '../services/announcement.service';
import { StudentService } from '../services/student.service';
import { RegistrationService } from '../services/registration.service';
import { sendSuccess, sendError } from '../utils/apiResponse';

const teamService = new TeamService();
const scoringService = new ScoringService();
const programService = new ProgramService();
const scheduleService = new ScheduleService();
const resultService = new ResultService();
const announcementService = new AnnouncementService();
const studentService = new StudentService();
const registrationService = new RegistrationService();

export async function getPublicTeams(req: Request, res: Response, next: NextFunction) {
  try {
    const teams = await teamService.getTeams();
    return sendSuccess(res, teams, 'Teams list');
  } catch (error) {
    next(error);
  }
}

export async function getPublicLeaderboard(req: Request, res: Response, next: NextFunction) {
  try {
    const section = (req.query.section as string) || 'ALL';
    const leaderboard = await scoringService.getLeaderboard(section);
    return sendSuccess(res, leaderboard, 'Leaderboard data');
  } catch (error) {
    next(error);
  }
}

export async function getPublicPrograms(req: Request, res: Response, next: NextFunction) {
  try {
    const section = req.query.section as string;
    const category = req.query.category as string;
    const programs = await programService.getPrograms({ section, category });
    return sendSuccess(res, programs, 'Programs list');
  } catch (error) {
    next(error);
  }
}

export async function getPublicSchedules(req: Request, res: Response, next: NextFunction) {
  try {
    const schedules = await scheduleService.getSchedules();
    return sendSuccess(res, schedules, 'Schedules list');
  } catch (error) {
    next(error);
  }
}

export async function getPublicResults(req: Request, res: Response, next: NextFunction) {
  try {
    const section = req.query.section as string;
    const programId = req.query.programId as string;
    let results = await resultService.getPublishedResults(section);

    if (programId) {
      results = results.filter((r) => r.programId === programId);
    }

    return sendSuccess(res, results, 'Published results');
  } catch (error) {
    next(error);
  }
}

export async function getPublicAnnouncements(req: Request, res: Response, next: NextFunction) {
  try {
    const announcements = await announcementService.getAnnouncements(true);
    return sendSuccess(res, announcements, 'Active announcements');
  } catch (error) {
    next(error);
  }
}

export async function getPublicRegistrations(req: Request, res: Response, next: NextFunction) {
  try {
    const studentId = req.query.studentId as string;
    const programId = req.query.programId as string;
    const teamId = req.query.teamId as string;
    const registrations = await registrationService.getRegistrations({ studentId, programId, teamId });
    return sendSuccess(res, registrations, 'Public registrations');
  } catch (error) {
    next(error);
  }
}

export async function getPublicStudentByChase(req: Request, res: Response, next: NextFunction) {
  try {
    const rawChase = req.params.chaseNumber?.trim() || '';
    if (!rawChase) return sendError(res, 'Chase number is required', 400, 'BAD_REQUEST');

    let student = await studentService.getStudentByChaseNumber(rawChase);
    if (!student) {
      student = await studentService.getStudentById(rawChase);
    }
    if (!student) {
      // Try searching across all students with query matching
      const allMatches = await studentService.getStudents({ query: rawChase });
      const qClean = rawChase.toLowerCase().replace(/[^a-z0-9]/g, '');
      student = allMatches.find((s) => {
        const sChase = (s.chaseNumber || '').toLowerCase().replace(/[^a-z0-9]/g, '');
        const sId = (s.id || '').toLowerCase();
        const sName = (s.name || '').toLowerCase();
        return sChase === qClean || sChase.endsWith(qClean) || sChase.includes(qClean) || sId === rawChase.toLowerCase() || sName.includes(rawChase.toLowerCase());
      }) || (allMatches.length > 0 ? allMatches[0] : null);
    }
    if (!student) return sendError(res, 'Student not found', 404, 'NOT_FOUND');
    return sendSuccess(res, student, 'Student details');
  } catch (error) {
    next(error);
  }
}
