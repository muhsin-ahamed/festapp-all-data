import { Request, Response, NextFunction } from 'express';
import { TvService } from '../services/tv.service';
import { ScoringService } from '../services/scoring.service';
import { ResultService } from '../services/result.service';
import { AnnouncementService } from '../services/announcement.service';
import { sendSuccess } from '../utils/apiResponse';

const tvService = new TvService();
const scoringService = new ScoringService();
const resultService = new ResultService();
const announcementService = new AnnouncementService();

export async function getTvSettings(req: Request, res: Response, next: NextFunction) {
  try {
    const settings = await tvService.getSettings();
    return sendSuccess(res, settings, 'TV settings');
  } catch (error) {
    next(error);
  }
}

export async function updateTvSettings(req: Request, res: Response, next: NextFunction) {
  try {
    const updated = await tvService.updateSettings(req.body, req.user?.username);
    return sendSuccess(res, updated, 'TV settings updated');
  } catch (error) {
    next(error);
  }
}

export async function getTvLive(req: Request, res: Response, next: NextFunction) {
  try {
    const section = (req.query.section as string) || 'ALL';
    const settings = await tvService.getSettings();
    const leaderboard = await scoringService.getLeaderboard(section);
    const publishedResults = await resultService.getPublishedResults(section);
    const announcements = await announcementService.getAnnouncements(true);

    return sendSuccess(
      res,
      {
        settings,
        topTeams: leaderboard.slice(0, settings.showTopTeamsCount || 5),
        recentResults: publishedResults.slice(0, 10),
        activeAnnouncements: announcements,
      },
      'TV live display data'
    );
  } catch (error) {
    next(error);
  }
}
