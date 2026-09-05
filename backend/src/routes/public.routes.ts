import { Router } from 'express';
import * as PublicController from '../controllers/public.controller';

const router = Router();

router.get('/teams', PublicController.getPublicTeams);
router.get('/leaderboard', PublicController.getPublicLeaderboard);
router.get('/programs', PublicController.getPublicPrograms);
router.get('/schedules', PublicController.getPublicSchedules);
router.get('/results', PublicController.getPublicResults);
router.get('/announcements', PublicController.getPublicAnnouncements);
router.get('/student/:chaseNumber', PublicController.getPublicStudentByChase);

export default router;
