import { Request, Response, NextFunction } from 'express';
import { ScheduleService } from '../services/schedule.service';
import { sendSuccess } from '../utils/apiResponse';

const scheduleService = new ScheduleService();

export async function getSchedules(req: Request, res: Response, next: NextFunction) {
  try {
    const schedules = await scheduleService.getSchedules();
    return sendSuccess(res, schedules, 'Schedules list');
  } catch (error) {
    next(error);
  }
}

export async function createSchedule(req: Request, res: Response, next: NextFunction) {
  try {
    const created = await scheduleService.createSchedule(req.body, req.user?.username);
    return sendSuccess(res, created, 'Schedule created', 201);
  } catch (error) {
    next(error);
  }
}

export async function getVenues(req: Request, res: Response, next: NextFunction) {
  try {
    const venues = await scheduleService.getVenues();
    return sendSuccess(res, venues, 'Venues list');
  } catch (error) {
    next(error);
  }
}

export async function createVenue(req: Request, res: Response, next: NextFunction) {
  try {
    const created = await scheduleService.createVenue(req.body, req.user?.username);
    return sendSuccess(res, created, 'Venue created', 201);
  } catch (error) {
    next(error);
  }
}
