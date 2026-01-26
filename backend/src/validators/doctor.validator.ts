import { z } from 'zod'
import { therapy_drug } from '.'

const dosageScheduleSchema = z.object({
  monday: z.number().default(0),
  tuesday: z.number().default(0),
  wednesday: z.number().default(0),
  thursday: z.number().default(0),
  friday: z.number().default(0),
  saturday: z.number().default(0),
  sunday: z.number().default(0)
}).optional()

const ddmmyyyy = z.string("Therapy_date Should be a valid date")
  .regex(/^\d{2}-\d{2}-\d{4}$/ , "Date must be in DD-MM-YYYY format")
  .transform((val) => {
    const [day, month, year] = val.split('-').map(Number)
    return new Date(year, month - 1, day)
  })

const medicalHistorySchema = z.object({
  diagnosis: z.string().optional(),
  duration_value: z.number().optional(),
  duration_unit: z.enum(['Days', 'Weeks', 'Months', 'Years']).optional(),
})

export const createPatient = z.object({
  body: z.object({
    name: z.string("Name should be a String").nonempty("Name Should Not be Empty"),
    op_num: z.string("Op num should be a String").nonempty("op_num should not be nonempty"),
    age: z.number("age should be a number").max(100, "Age cannot exceed 100").optional(),
    gender: z.enum(["Male", "Female", "Other"], "The gender should be a valid option"),
    contact_no: z.string("Contact number should be a string").length(10, "Contact number must be exactly 10 digits"),
    target_inr_min: z.number("target_inr_min should be a number").optional(),
    target_inr_max: z.number("target_inr_max should be a number").optional(),
    therapy: z.enum(therapy_drug, "Therapy Drug Should only Take The given Drug Values").optional(),
    therapy_start_date: ddmmyyyy.optional(),
    prescription: dosageScheduleSchema,
    medical_history: z.array(medicalHistorySchema).optional(),
    kin_name: z.string("kin_name should be string").optional(),
    kin_relation: z.string("Relation should be string").optional(),
    kin_contact_number: z.string("contact_number should be a string"),
  })
})

export type CreatePatientInput = z.infer<typeof createPatient>

