import { Request, Response, NextFunction } from 'express';
import { UserRole } from '../types';
import { sendError } from '../utils/apiResponse';

export function authorize(...allowedRoles: UserRole[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return sendError(res, 'Unauthenticated', 401, 'UNAUTHORIZED');
    }

    if (!allowedRoles.includes(req.user.role)) {
      return sendError(res, 'Forbidden: Insufficient role permissions', 403, 'FORBIDDEN');
    }

    next();
  };
}

export function requireTeamLeader(req: Request, res: Response, next: NextFunction) {
  if (!req.user) {
    return sendError(res, 'Unauthenticated', 401, 'UNAUTHORIZED');
  }

  if (req.user.role !== 'TEAM_LEADER' && req.user.role !== 'FEST_CONTROLLER') {
    return sendError(res, 'Forbidden: Team Leader access required', 403, 'FORBIDDEN');
  }

  if (req.user.role === 'TEAM_LEADER' && !req.user.teamId) {
    return sendError(res, 'Forbidden: Team Leader does not have an assigned team', 403, 'NO_TEAM_ASSIGNED');
  }

  next();
}

export function requireJury(req: Request, res: Response, next: NextFunction) {
  if (!req.user) {
    return sendError(res, 'Unauthenticated', 401, 'UNAUTHORIZED');
  }

  if (req.user.role !== 'JURY' && req.user.role !== 'FEST_CONTROLLER') {
    return sendError(res, 'Forbidden: Jury access required', 403, 'FORBIDDEN');
  }

  next();
}
