import { Router } from 'express';
import * as AnnouncementController from '../controllers/announcement.controller';
import { authenticate } from '../middleware/auth.middleware';
import { authorize } from '../middleware/role.middleware';

const router = Router();

router.get('/', AnnouncementController.getAnnouncements);
router.post('/', authenticate, authorize('FEST_CONTROLLER'), AnnouncementController.createAnnouncement);
router.put('/:id', authenticate, authorize('FEST_CONTROLLER'), AnnouncementController.updateAnnouncement);
router.delete('/:id', authenticate, authorize('FEST_CONTROLLER'), AnnouncementController.deleteAnnouncement);

export default router;
