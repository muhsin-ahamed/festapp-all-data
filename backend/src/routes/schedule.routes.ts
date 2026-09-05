import { Router } from 'express';
import * as ScheduleController from '../controllers/schedule.controller';
import { authenticate } from '../middleware/auth.middleware';
import { authorize } from '../middleware/role.middleware';

const router = Router();

router.get('/schedules', ScheduleController.getSchedules);
router.post('/schedules', authenticate, authorize('FEST_CONTROLLER'), ScheduleController.createSchedule);
router.get('/venues', ScheduleController.getVenues);
router.post('/venues', authenticate, authorize('FEST_CONTROLLER'), ScheduleController.createVenue);

export default router;
