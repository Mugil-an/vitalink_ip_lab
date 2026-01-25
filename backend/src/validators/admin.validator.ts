import { z } from 'zod'

export const craeteDoctor = z.object({
  body: z.object({
    name: z.string("Name should be a String").nonempty("Name Should Not be Empty")
    department: z.string("Department Should be a string").nonempty("Department should be Non Empty"),
    password: z.string("Password Should be a string").min(3, "Password Should have a Minimum length of Three").max(12, "Passowrd Should be a Maxmimum Length of 12"),
    contact_number: z.string("contact_number should be string")
  })
})
