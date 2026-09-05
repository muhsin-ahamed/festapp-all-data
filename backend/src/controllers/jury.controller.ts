import { Request, Response, NextFunction } from 'express';
import { JuryService } from '../services/jury.service';
import { ResultService } from '../services/result.service';
import { RegistrationService } from '../services/registration.service';
import { sendSuccess, sendError } from '../utils/apiResponse';

const juryService = new JuryService();
const resultService = new ResultService();
const registrationService = new RegistrationService();

export async function getJuryDashboard(req: Request, res: Response, next: NextFunction) {
  try {
    const juryId = req.user?.juryId || req.user?.id || '';
    const programs = await juryService.getAssignedPrograms(juryId);
    const results = await resultService.getResults({ juryId });

    return sendSuccess(
      res,
      {
        assignedProgramsCount: programs.length,
        submittedEvaluationsCount: results.length,
        assignedPrograms: programs,
      },
      'Jury dashboard details'
    );
  } catch (error) {
    next(error);
  }
}

export async function getJuryPrograms(req: Request, res: Response, next: NextFunction) {
  try {
    const juryId = req.user?.juryId || req.user?.id || '';
    const programs = await juryService.getAssignedPrograms(juryId);
    return sendSuccess(res, programs, 'Assigned programs list');
  } catch (error) {
    next(error);
  }
}

export async function getProgramParticipants(req: Request, res: Response, next: NextFunction) {
  try {
    const programId = req.params.id;
    const juryId = req.user?.juryId || req.user?.id || '';

    // If role is JURY, ensure jury is assigned to this program
    if (req.user?.role === 'JURY') {
      const assignedPrograms = await juryService.getAssignedPrograms(juryId);
      const isAssigned = assignedPrograms.some((p) => p.id === programId);
      if (!isAssigned) {
        return sendError(res, 'Forbidden: Jury is not assigned to this program', 403, 'JURY_NOT_ASSIGNED');
      }
    }

    const registrations = await registrationService.getRegistrations({ programId });
    return sendSuccess(res, registrations, 'Program participants');
  } catch (error) {
    next(error);
  }
}

export async function scanQrCode(req: Request, res: Response, next: NextFunction) {
  try {
    const { payload } = req.body;
    if (!payload) return sendError(res, 'QR payload is required', 400, 'BAD_REQUEST');

    const juryId = req.user?.juryId || req.user?.id || '';
    const scanResult = await juryService.verifyScan(payload, juryId, req.user?.role || '');

    return sendSuccess(res, scanResult, 'QR code validated successfully');
  } catch (error) {
    next(error);
  }
}

export async function submitJuryResult(req: Request, res: Response, next: NextFunction) {
  try {
    const { programId, studentId, marks, grade, position, remarks, isDraft } = req.body;
    const juryId = req.user?.juryId || req.user?.id || '';

    if (req.user?.role === 'JURY') {
      const assignedPrograms = await juryService.getAssignedPrograms(juryId);
      const isAssigned = assignedPrograms.some((p) => p.id === programId);
      if (!isAssigned) {
        return sendError(res, 'Forbidden: Jury is not assigned to evaluate this program', 403, 'JURY_NOT_ASSIGNED');
      }
    }

    const result = await resultService.submitJuryResult(
      programId,
      studentId,
      marks,
      grade,
      position,
      remarks,
      juryId,
      req.user?.username,
      isDraft
    );

    return sendSuccess(res, result, 'Evaluation submitted successfully', 201);
  } catch (error) {
    next(error);
  }
}

export async function getJuryResults(req: Request, res: Response, next: NextFunction) {
  try {
    const juryId = req.user?.juryId || req.user?.id || '';
    const results = await resultService.getResults({ juryId });
    return sendSuccess(res, results, 'Submitted evaluations');
  } catch (error) {
    next(error);
  }
}
