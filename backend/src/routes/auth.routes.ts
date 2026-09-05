import { Router } from 'express';
import * as AuthController from '../controllers/auth.controller';
import { authenticate } from '../middleware/auth.middleware';
import { validateRequest } from '../middleware/validation.middleware';
import { loginSchema, changePasswordSchema, updateUsernameSchema } from '../validators/auth.validator';

const router = Router();

router.post('/login', validateRequest({ body: loginSchema }), AuthController.login);
router.post('/logout', AuthController.logout);
router.get('/me', authenticate, AuthController.getMe);
router.post('/change-password', authenticate, validateRequest({ body: changePasswordSchema }), AuthController.changePassword);
router.put('/username', authenticate, validateRequest({ body: updateUsernameSchema }), AuthController.updateUsername);

export default router;
