import { Router } from 'express'
import multer from 'multer'
import { authenticate, AllowPatient, validate } from '@alias/middlewares'
import {
	getProfile,
	missedDoses,
	getReport,
	submitReport,
	takeDosage,
	getDosageCalendar,
	updateHealthLogs,
	updateProfilePicture,
	updateProfile,
} from '@alias/controllers/patient.controller'
import { reportSchema, takeDosageSchema, updateHealthLogSchema, updateProfileSchema } from '@alias/validators/patient.validator'

const upload = multer({ dest: 'uploads/reports/' })
const uploadpic = multer({ dest: 'uploads/profiles' })

const router = Router()

router.route('/profile').get(authenticate, AllowPatient, getProfile).put(authenticate, AllowPatient, validate(updateProfileSchema), updateProfile)
router.get('/reports', authenticate, AllowPatient, getReport)
router.post('/reports', authenticate, AllowPatient, upload.single('file'), validate(reportSchema), submitReport)
router.get('/missed-doses', authenticate, AllowPatient, missedDoses)
router.get('/dosage-calendar', authenticate, AllowPatient, getDosageCalendar)
router.post('/dosage', authenticate, AllowPatient, validate(takeDosageSchema), takeDosage)
router.post('/health-logs', authenticate, AllowPatient, validate(updateHealthLogSchema), updateHealthLogs)
router.post("/profile-pic", authenticate, AllowPatient, uploadpic.single('file'), updateProfilePicture)

export default router
