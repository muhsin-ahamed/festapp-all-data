import { z } from 'zod';

export const createRegistrationSchema = z.object({
  studentId: z.string().min(1, 'Student ID is required'),
  programId: z.string().min(1, 'Program ID is required'),
});
