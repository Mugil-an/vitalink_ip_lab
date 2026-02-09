import { Router } from 'express'
import { authenticate, AllowAdmin, validate } from '@alias/middlewares'
import {
	createDoctor,
	getAllDoctors,
	getDoctorById,
	updateDoctor,
	createPatient,
	listAllPatients,
	getPatientById,
	updatePatient,
	reassignPatient,
} from '@alias/controllers/admin.controller'
import {
	createDoctor as createDoctorSchema,
	createPatient as createPatientSchema,
	updateDoctor as updateDoctorSchema,
	updatePatient as updatePatientSchema,
	reassignPatientSchema,
} from '@alias/validators/admin.validator'

const router = Router()

// Doctor management
router.post('/doctors', authenticate, AllowAdmin, validate(createDoctorSchema), createDoctor)
router.get('/doctors', authenticate, AllowAdmin, getAllDoctors)
router.get('/doctors/:id', authenticate, AllowAdmin, getDoctorById)
router.put('/doctors/:id', authenticate, AllowAdmin, validate(updateDoctorSchema), updateDoctor)

// Patient management
router.post('/patients', authenticate, AllowAdmin, validate(createPatientSchema), createPatient)
router.get('/patients', authenticate, AllowAdmin, listAllPatients)
router.get('/patients/:op_num', authenticate, AllowAdmin, getPatientById)
router.put('/patients/:op_num', authenticate, AllowAdmin, validate(updatePatientSchema), updatePatient)
router.patch('/patients/:op_num/reassign', authenticate, AllowAdmin, validate(reassignPatientSchema), reassignPatient)

export default router
