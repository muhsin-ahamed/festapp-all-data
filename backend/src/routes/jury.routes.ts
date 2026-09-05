import { Router } from 'express';
import * as JuryController from '../controllers/jury.controller';
import { authenticate } from '../middleware/auth.middleware';
import { requireJury } from '../middleware/role.middleware';
import { validateRequest } from '../middleware/validation.middleware';
import { submitResultSchema } from '../validators/result.validator';

const router = Router();

router.use(authenticate, requireJury);

router.get('/dashboard', JuryController.getJuryDashboard);
router.get('/programs', JuryController.getJuryPrograms);
router.get('/programs/:id/participants', JuryController.getProgramParticipants);
router.post('/scan', JuryController.scanQrCode);
router.post('/results', validateRequest({ body: submitResultSchema }), JuryController.submitJuryResult);
router.get('/results', JuryController.getJuryResults);

export default router;
