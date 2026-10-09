import { Router } from 'express';
import * as TvController from '../controllers/tv.controller';
import { authenticate } from '../middleware/auth.middleware';
import { authorize } from '../middleware/role.middleware';

const router = Router();

// Public TV live feed
router.get('/live', TvController.getTvLive);

// Protected TV settings
router.get('/settings', authenticate, TvController.getTvSettings);
router.put('/settings', authenticate, authorize('TV_OPERATOR', 'FEST_CONTROLLER'), TvController.updateTvSettings);

export default router;
