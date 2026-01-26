import {z} from 'zod'
import { UserType } from './index'

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

export type LoginInput = z.infer<typeof loginSchema> 



