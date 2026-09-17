import { z } from 'zod';

export const submitResultSchema = z.object({
  programId: z.string().min(1, 'Program ID is required'),
  studentId: z.string().min(1, 'Student ID is required'),
  marks: z.number().min(0, 'Marks must be non-negative'),
  grade: z.string().nullish(),
  position: z.number().int().nullish(),
  remarks: z.string().nullish(),
  isDraft: z.boolean().optional(),
});
