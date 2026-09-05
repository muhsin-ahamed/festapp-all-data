import { Request, Response, NextFunction } from 'express';
import { logger } from '../utils/logger';
import { sendError } from '../utils/apiResponse';

export function errorHandler(err: any, req: Request, res: Response, next: NextFunction) {
  logger.error(`Error on ${req.method} ${req.originalUrl}:`, err);

  let statusCode = err.statusCode || err.status || 500;
  let message = err.message || 'Internal Server Error';
  let code = err.code || 'INTERNAL_SERVER_ERROR';

  // Handle PostgREST & PostgreSQL database error codes
  if (code === 'PGRST204' || code === '42703') {
    statusCode = 400;
    message = `Database schema mismatch: ${err.message || 'A required database column is missing in Supabase.'}`;
    code = 'SCHEMA_COLUMN_MISSING';
  } else if (code === '23505') {
    statusCode = 409;
    message = `Duplicate record: A resource with these unique parameters already exists.`;
    code = 'DUPLICATE_RESOURCE';
  } else if (code === '23503') {
    statusCode = 422;
    message = `Foreign key reference error: Associated record does not exist in the database.`;
    code = 'FOREIGN_KEY_VIOLATION';
  }

  return sendError(res, message, statusCode, code);
}
