import {z} from 'zod'
import { UserType } from './index'

const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/

export const registerSchema = z.object({
  body: z.object({
    login_id: z
      .string()
      .min(3, 'Login ID must be at least 3 characters')
      .max(50, 'Login ID must not exceed 50 characters')
      .regex(/^[a-zA-Z0-9_@.-]+$/, 'Login ID can only contain letters, numbers, underscores, dots, hyphens, and @'),
    password: z
      .string()
      .min(8, 'Password must be at least 8 characters')
      .regex(passwordRegex, 'Password must contain uppercase, lowercase, number, and special character (@$!%*?&)'),
    confirm_password: z
      .string()
      .min(8, 'Confirm password is required'),
    user_type: z
      .enum([UserType.ADMIN, UserType.DOCTOR, UserType.PATIENT])
      .refine(type => type !== UserType.ADMIN, {
        message: 'Admin users cannot self-register. Please contact system administrator.',
        path: ['user_type'],
      }),
  })
  .refine(data => data.password === data.confirm_password, {
    message: 'Passwords do not match',
    path: ['confirm_password'],
  })
  .and(
    z.object({
      body: z.object({
        doctor_details: z.object({
          department: z.string().optional(),
        }).optional(),
        patient_details: z.object({
          name: z.string().min(1, 'Patient name is required').optional(),
          age: z.number().int().positive().optional(),
          gender: z.enum(['Male', 'Female', 'Other']).optional(),
          phone: z.string().optional(),
        }).optional(),
      })
    })
  ),
  query: z.object({}).optional(),
  params: z.object({}).optional(),
}).optional()

export const loginSchema = z.object({
  body: z.object({
    login_id: z
      .string()
      .min(1, 'Login ID is required'),
    password: z
      .string()
      .min(1, 'Password is required'),
  }),
  query: z.object({}).optional(),
  params: z.object({}).optional(),
}).optional()
