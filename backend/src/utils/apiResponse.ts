import { Response } from 'express';

export function sendSuccess(res: Response, data: any = {}, message: string = 'Operation successful', statusCode: number = 200) {
  return res.status(statusCode).json({
    success: true,
    data,
    message,
  });
}

export function sendError(res: Response, message: string = 'An error occurred', statusCode: number = 400, code: string = 'BAD_REQUEST') {
  return res.status(statusCode).json({
    success: false,
    message,
    code,
  });
}
