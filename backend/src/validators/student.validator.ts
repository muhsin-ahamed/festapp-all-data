import { z } from 'zod';

export const createStudentSchema = z.object({
  chaseNumber: z.string().min(1, 'Chase number is required'),
  name: z.string().min(1, 'Student name is required'),
  gender: z.string().min(1, 'Gender is required'),
  dateOfBirth: z.string().optional(),
  section: z.string().min(1, 'Section is required'),
  teamId: z.string().min(1, 'Team ID is required'),
  phone: z.string().optional(),
  className: z.string().optional(),
  schoolName: z.string().optional(),
});

export const updateStudentSchema = createStudentSchema.partial();
