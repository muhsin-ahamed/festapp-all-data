import { Request, Response, NextFunction } from 'express';
import { AnnouncementService } from '../services/announcement.service';
import { sendSuccess } from '../utils/apiResponse';

const announcementService = new AnnouncementService();

export async function getAnnouncements(req: Request, res: Response, next: NextFunction) {
  try {
    const activeOnly = req.query.activeOnly === 'true';
    const announcements = await announcementService.getAnnouncements(activeOnly);
    return sendSuccess(res, announcements, 'Announcements list');
  } catch (error) {
    next(error);
  }
}

export async function createAnnouncement(req: Request, res: Response, next: NextFunction) {
  try {
    const created = await announcementService.createAnnouncement(req.body, req.user?.username);
    return sendSuccess(res, created, 'Announcement created', 201);
  } catch (error) {
    next(error);
  }
}

export async function updateAnnouncement(req: Request, res: Response, next: NextFunction) {
  try {
    const updated = await announcementService.updateAnnouncement(req.params.id, req.body, req.user?.username);
    return sendSuccess(res, updated, 'Announcement updated');
  } catch (error) {
    next(error);
  }
}

export async function deleteAnnouncement(req: Request, res: Response, next: NextFunction) {
  try {
    await announcementService.deleteAnnouncement(req.params.id, req.user?.username);
    return sendSuccess(res, {}, 'Announcement deleted');
  } catch (error) {
    next(error);
  }
}
