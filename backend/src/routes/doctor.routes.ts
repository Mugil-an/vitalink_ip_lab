import { Router } from 'express'
import { authenticate, AllowDoctor, validate } from '@src/middlewares'
import {
    addPatient,
    editPatientDosage,
    getPatients,
    getProfile,
    getReports,
    getDoctors,
    reassignPatient,
    updateNextReview,
    viewPatient,
    UpdateProfile,
} from '@src/controllers/doctor.controller'
import { createPatient } from '@src/validators/doctor.validator'

const router = Router()


router.get('/patients', authenticate, AllowDoctor, getPatients)
router.get('/patients/:op_num', authenticate, AllowDoctor, viewPatient)
router.post('/patients', authenticate, AllowDoctor, validate(createPatient), addPatient)
router.patch('/patients/:op_num/reassign', authenticate, AllowDoctor, reassignPatient)
router.put('/patients/:op_num/dosage', authenticate, AllowDoctor, editPatientDosage)
router.get('/patients/:op_num/reports', authenticate, AllowDoctor, getReports)
router.put('/patients/:op_num/config', authenticate, AllowDoctor, updateNextReview)

router.get('/profile', authenticate, AllowDoctor, getProfile)
router.put('/profile', authenticate, AllowDoctor, UpdateProfile)
router.get('/doctors', authenticate, AllowDoctor, getDoctors)

export default router