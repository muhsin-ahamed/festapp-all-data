import { Request, Response, NextFunction } from 'express';
import { TeamService } from '../services/team.service';
import { ScoringService } from '../services/scoring.service';
import { ProgramService } from '../services/program.service';
import { ScheduleService } from '../services/schedule.service';
import { ResultService } from '../services/result.service';
import { AnnouncementService } from '../services/announcement.service';
import { StudentService } from '../services/student.service';
import { sendSuccess, sendError } from '../utils/apiResponse';

const teamService = new TeamService();
const scoringService = new ScoringService();
const programService = new ProgramService();
const scheduleService = new ScheduleService();
const resultService = new ResultService();
const announcementService = new AnnouncementService();
const studentService = new StudentService();

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

export async function getPublicStudentByChase(req: Request, res: Response, next: NextFunction) {
  try {
    const chaseNumber = req.params.chaseNumber;
    const student = await studentService.getStudentByChaseNumber(chaseNumber);
    if (!student) return sendError(res, 'Student not found', 404, 'NOT_FOUND');
    return sendSuccess(res, student, 'Student details');
  } catch (error) {
    next(error);
  }
}
