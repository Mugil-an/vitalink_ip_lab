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
    updateProfilePicture,
    updateReport,
} from '@src/controllers/doctor.controller'
import { createPatient, UpdateReportSchema } from '@src/validators/doctor.validator'
import multer from 'multer'

const upload = multer({ dest: 'uploads/profiles/' })

const router = Router()


router.get('/patients', authenticate, AllowDoctor, getPatients)
router.get('/patients/:op_num', authenticate, AllowDoctor, viewPatient)
router.post('/patients', authenticate, AllowDoctor, validate(createPatient), addPatient)
router.patch('/patients/:op_num/reassign', authenticate, AllowDoctor, reassignPatient)
router.put('/patients/:op_num/dosage', authenticate, AllowDoctor, editPatientDosage)
router.route('/patients/:op_num/reports').get(authenticate, AllowDoctor, getReports)

router.route('/patients/:op_num/reports/:report_id').put(authenticate, AllowDoctor, validate(UpdateReportSchema), updateReport)

router.put('/patients/:op_num/config', authenticate, AllowDoctor, updateNextReview)
router.get('/profile', authenticate, AllowDoctor, getProfile)
router.put('/profile', authenticate, AllowDoctor, UpdateProfile)
router.get('/doctors', authenticate, AllowDoctor, getDoctors)
router.post("/profile-pic", authenticate, AllowDoctor, upload.single('file'), updateProfilePicture)

export default router