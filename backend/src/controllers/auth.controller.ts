import { Request, Response, NextFunction } from 'express';
import { AuthService } from '../services/auth.service';
import { sendSuccess, sendError } from '../utils/apiResponse';

const authService = new AuthService();

export async function login(req: Request, res: Response, next: NextFunction) {
  try {
    const { username, password } = req.body;
    const result = await authService.login(username, password);
    return sendSuccess(res, result, 'Login successful');
  } catch (error) {
    next(error);
  }
}

export async function logout(req: Request, res: Response) {
  return sendSuccess(res, {}, 'Logout successful');
}

export async function getMe(req: Request, res: Response, next: NextFunction) {
  try {
    if (!req.user) return sendError(res, 'Unauthenticated', 401, 'UNAUTHORIZED');
    const user = await authService.getUserById(req.user.id);
    if (!user) return sendError(res, 'User not found', 404, 'USER_NOT_FOUND');
    return sendSuccess(res, user, 'Current user profile');
  } catch (error) {
    next(error);
  }
}

export async function changePassword(req: Request, res: Response, next: NextFunction) {
  try {
    if (!req.user) return sendError(res, 'Unauthenticated', 401, 'UNAUTHORIZED');
    const { currentPassword, newPassword } = req.body;
    await authService.changePassword(req.user.id, currentPassword, newPassword);
    return sendSuccess(res, {}, 'Password changed successfully');
  } catch (error) {
    next(error);
  }
}

export async function updateUsername(req: Request, res: Response, next: NextFunction) {
  try {
    if (!req.user) return sendError(res, 'Unauthenticated', 401, 'UNAUTHORIZED');
    const { username } = req.body;
    const updated = await authService.updateUsername(req.user.id, username);
    return sendSuccess(res, updated, 'Username updated successfully');
  } catch (error) {
    next(error);
  }
}
