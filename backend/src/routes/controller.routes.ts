import { Router } from 'express';
import * as Controller from '../controllers/controller.controller';
import { authenticate } from '../middleware/auth.middleware';
import { authorize } from '../middleware/role.middleware';
import { validateRequest } from '../middleware/validation.middleware';
import { createStudentSchema } from '../validators/student.validator';
import { createRegistrationSchema } from '../validators/registration.validator';

const router = Router();

router.use(authenticate, authorize('FEST_CONTROLLER'));

// Dashboard
router.get('/dashboard', Controller.getDashboard);

// Students Management
router.get('/students', Controller.getStudents);
router.post('/students', validateRequest({ body: createStudentSchema }), Controller.addStudent);
router.put('/students/:id', Controller.updateStudent);
router.delete('/students/:id', Controller.deleteStudent);
router.post('/students/import', Controller.importStudentsExcel);
router.get('/students/export', Controller.exportStudentsExcel);

// Teams Management
router.get('/teams', Controller.getTeams);
router.post('/teams', Controller.addTeam);
router.put('/teams/:id', Controller.updateTeam);
router.delete('/teams/:id', Controller.deleteTeam);

// Programs Management
router.get('/programs', Controller.getPrograms);
router.post('/programs', Controller.addProgram);
router.put('/programs/:id', Controller.updateProgram);
router.delete('/programs/:id', Controller.deleteProgram);

// Program Registrations Management
router.get('/registrations', Controller.getRegistrations);
router.post('/registrations', validateRequest({ body: createRegistrationSchema }), Controller.addRegistration);
router.delete('/registrations/:id', Controller.deleteRegistration);
router.post('/registrations/import', Controller.importRegistrationsExcel);
router.get('/registrations/template', Controller.downloadRegistrationTemplate);

// Results Workflow
router.get('/results', Controller.getResults);
router.post('/results/verify/:id', Controller.verifyResult);
router.post('/results/publish/:id', Controller.publishResult);
router.delete('/results/:id', Controller.deleteResult);

// Jury Management
router.get('/juries', Controller.getJuries);
router.post('/juries/assign-program', Controller.assignJuryProgram);

// Audit Logs
router.get('/audit-logs', Controller.getAuditLogs);

export default router;
