import { z } from 'zod'

export const createDoctor = z.object({
  body: z.object({
    login_id: z.string("Login ID should be a String").nonempty("Login ID should not be empty"),
    name: z.string("Name should be a String").nonempty("Name Should Not be Empty"),
    department: z.string("Department Should be a string").nonempty("Department should be Non Empty"),
    password: z.string("Password Should be a string").min(3, "Password Should have a Minimum length of Three").max(12, "Passowrd Should be a Maxmimum Length of 12"),
    contact_number: z.string("contact_number should be string")
  })
})
export type createDoctorType = z.infer<typeof createDoctor>

export const createPatient = z.object({
  body: z.object({
    name: z.string("Name should be a String").nonempty("Name Should Not be Empty"),
    password: z.string("Password Should be a string").min(3, "Password Should have a Minimum length of Three").max(12, "Passowrd Should be a Maxmimum Length of 12"),
    op_num: z.string("Op num should be a String").nonempty("op_num should not be nonempty"),
    age: z.number("age should be a number").max(100, "Age cannot exceed 100").optional(),
    gender: z.enum(["Male", "Female", "Other"], "The gender should be a valid option"),
    assigned_doctor_id: z.string("Doctor Should be assigned to a patient").nonempty("Doctor should not be empty"),
    kin_name: z.string("kin_name should be string").optional(),
    kin_relation: z.string("Relation should be string").optional(),
    kin_contact_number: z.string("contact_number should be a string"),
  })
})
export type createPatientType = z.infer<typeof createPatient>

export const updateDoctor = z.object({
  params: z.object({
    id: z.string("Login ID should be a String").nonempty("Login ID should not be empty"),
  }),
  body: z.object({
    name: z.string("Name should be a String").optional(),
    password: z.string("Password Should be a string").min(3, "Password Should have a Minimum length of Three").max(12, "Passowrd Should be a Maxmimum Length of 12"),
    department: z.string("Department Should be a string").optional(),
    contact_number: z.string("contact_number should be string").optional(),
  }).strict(),
})
export type updateDoctorType = z.infer<typeof updateDoctor>


export const updatePatient = z.object({
  params: z.object({
    op_num: z.string("Op num should be a String").nonempty("op_num should not be nonempty")
  }),
  body: z.object({
    name: z.string("Name should be a String").optional(),
    age: z.number("age should be a number").max(100, "Age cannot exceed 100").optional(),
    gender: z.enum(["Male", "Female", "Other"], "The gender should be a valid option").optional(),
    password: z.string("Password Should be a string").min(3, "Password Should have a Minimum length of Three").max(12, "Passowrd Should be a Maxmimum Length of 12"),
    kin_name: z.string("kin_name should be string").optional(),
    kin_relation: z.string("Relation should be string").optional(),
    kin_contact_number: z.string("contact_number should be a string").optional(),
    phone: z.string("phone should be a string").optional()
  }).strict()
})
export type updatePatientType = z.infer<typeof updatePatient>


export const reassignPatientSchema = z.object({
  params: z.object({
    op_num: z.string("Op num should be a String").nonempty("op_num should not be nonempty")
  }), 
  body: z.object({
    new_doctor_id: z.string("Doctor Id should be String")
  })
})
export type ReassignDoctorType = z.infer<typeof reassignPatientSchema>
