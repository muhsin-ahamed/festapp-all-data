import { Router } from 'express';
import * as LeaderController from '../controllers/leader.controller';
import { authenticate } from '../middleware/auth.middleware';
import { requireTeamLeader } from '../middleware/role.middleware';
import { validateRequest } from '../middleware/validation.middleware';
import { createStudentSchema } from '../validators/student.validator';
import { createRegistrationSchema } from '../validators/registration.validator';

const router = Router();

router.use(authenticate, requireTeamLeader);

router.get('/dashboard', LeaderController.getLeaderDashboard);
router.get('/team', LeaderController.getLeaderTeam);
router.get('/students', LeaderController.getLeaderStudents);
router.post('/students', validateRequest({ body: createStudentSchema }), LeaderController.addLeaderStudent);
router.post('/students/import-excel', LeaderController.importLeaderStudentsExcel);
router.put('/students/:id', LeaderController.updateLeaderStudent);
router.get('/programs', LeaderController.getLeaderPrograms);
router.post('/registrations', validateRequest({ body: createRegistrationSchema }), LeaderController.createLeaderRegistration);
router.get('/registrations', LeaderController.getLeaderRegistrations);
router.get('/results', LeaderController.getLeaderResults);

export default router;
