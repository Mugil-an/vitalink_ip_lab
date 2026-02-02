import { Request, Response } from 'express'
import { ApiError, ApiResponse, asyncHandler } from '@src/utils'
import { StatusCodes } from 'http-status-codes'
import { PatientProfile, User } from '@src/models'
import { UserType } from '@src/validators'
import type { ReportInput, TakeDosageInput, UpdateHealthLog, UpdateProfileInput } from '@src/validators/patient.validator'
import logger from '@src/utils/logger'
import { uploadFile } from '@src/utils/fileUpload'

export const getProfile = asyncHandler(async (req: Request, res: Response) => {
	const { user_id } = req.user
	const user = await User.findById(user_id).populate({
		path: 'profile_id',
		populate: {
			path: 'assigned_doctor_id',
			populate: {
				path: 'profile_id'
			}
		}
	})
	if (!user || user.user_type !== UserType.PATIENT) {
		throw new ApiError(StatusCodes.NOT_FOUND, 'Patient not found')
	}
	res.status(StatusCodes.OK).json(new ApiResponse(StatusCodes.OK, 'Profile fetched successfully', { patient: user }))
})

export const getReport = asyncHandler(async (req: Request, res: Response) => {
	if (!req.user) {
		throw new ApiError(StatusCodes.UNAUTHORIZED, 'Unauthorized')
	}

	const patientUser = await User.findById(req.user.user_id)
	if (!patientUser || patientUser.user_type !== UserType.PATIENT) {
		throw new ApiError(StatusCodes.NOT_FOUND, 'Patient not found')
	}

	const patient = await PatientProfile.findById(patientUser.profile_id).select('inr_history health_logs weekly_dosage medical_config')
	res.status(StatusCodes.OK).json(new ApiResponse(StatusCodes.OK, 'Report fetched', { report: patient }))
})

export const submitReport = asyncHandler(async (req: Request<{}, {}, ReportInput['body']>, res: Response) => {
	const { user_id } = req.user
	const patientUser = await User.findById(user_id)

	const { inr_value, test_date } = req.body
	const parsed_inr_value = parseFloat(inr_value)
	if (isNaN(parsed_inr_value)) {
		throw new ApiError(StatusCodes.BAD_REQUEST, 'INR value should be a valid number')
	}
	const file = (req as any).file as Express.Multer.File | undefined

	if (file) {
		const allowed = ['application/pdf', 'image/png', 'image/jpeg']
		if (!allowed.includes(file.mimetype)) {
			throw new ApiError(StatusCodes.BAD_REQUEST, 'Invalid file type. Only PDF, PNG, JPEG allowed')
		}
	}
	let fileUrl = ''
	try {
		fileUrl = await uploadFile("uploads", file)
	} catch (error) {
		logger.error("Error While Uploading File to filebase", { error })
		throw new ApiError(StatusCodes.INSUFFICIENT_STORAGE, "Error While Uploading report to cloud")
	}
	console.log(fileUrl)
	const patient = await PatientProfile.findByIdAndUpdate(
		patientUser.profile_id,
		{
			$push: {
				inr_history: {
					test_date: test_date,
					uploaded_at: new Date(),
					inr_value: parsed_inr_value,
					file_url: fileUrl,
				},
			},
		},
		{ new: true }
	)

	res.status(StatusCodes.OK).json(new ApiResponse(StatusCodes.OK, 'Report submitted', { patient }))
})

// TODO: Need to Review The Routes and Logic After This Later
export const missedDoses = asyncHandler(async (req: Request<{}, {}, {}>, res: Response) => {
	const patientUser = await User.findById(req.user.user_id)

	const patient = await PatientProfile.findById(patientUser.profile_id)
	if (!patient) {
		throw new ApiError(StatusCodes.NOT_FOUND, 'Patient profile not found')
	}

	const therapyStart = patient.medical_config?.therapy_start_date
	const dosage = patient.weekly_dosage as Record<string, number> | undefined
	if (!therapyStart || !dosage) {
		throw new ApiError(StatusCodes.BAD_REQUEST, 'Therapy start date or dosage schedule is missing')
	}

	const medicationDates = getMedicationDates(therapyStart, dosage)
	const takenDates: (Date | string)[] = (patient.medical_config?.taken_doses || []).map((d: any) =>
		d instanceof Date ? d : new Date(d)
	)
	const missed = findMissedDoses(medicationDates, takenDates)

	const today = new Date()
	const sevenDaysAgo = new Date()
	sevenDaysAgo.setDate(today.getDate() - 7)

	const recent_missed_doses: string[] = []
	const remaining_missed: string[] = []
	missed.forEach((d) => {
		const [day, month, year] = d.split('-').map(Number)
		const dateObj = new Date(year, month - 1, day)
		if (dateObj >= sevenDaysAgo && dateObj <= today) {
			recent_missed_doses.push(d)
		} else {
			remaining_missed.push(d)
		}
	})

	console.log("Recent Missed Doses", recent_missed_doses, remaining_missed)


	res.status(StatusCodes.OK).json(new ApiResponse(StatusCodes.OK, 'Missed doses calculated',
		{ recent_missed_doses, missed_doses: remaining_missed }))
})

export const takeDosage = asyncHandler(async (req: Request<{}, {}, TakeDosageInput['body']>, res: Response) => {
	const patientUser = await User.findById(req.user.user_id)

	const { date } = req.body
	const parsedDate = date instanceof Date ? date : parseDDMMYYYY(date)

	const patient = await PatientProfile.findByIdAndUpdate(
		patientUser.profile_id,
		{
			$push: {
				'medical_config.taken_doses': parsedDate,
			},
		},
		{ new: true }
	)

	res.status(StatusCodes.OK).json(new ApiResponse(StatusCodes.OK, 'Dosage logged', { patient }))
})

export const updateProfile = asyncHandler(async (req: Request<{}, {}, UpdateProfileInput['body']>, res: Response) => {
    const { user_id } = req.user
    const { demographics, medical_history, medical_config } = req.body

    const user = await User.findById(user_id)
    if (!user || user.user_type !== UserType.PATIENT) {
        throw new ApiError(StatusCodes.NOT_FOUND, 'Patient not found')
    }

    const updateData: any = {}

    if (demographics) {
        if (demographics.name) updateData['demographics.name'] = demographics.name
        if (demographics.age !== undefined) updateData['demographics.age'] = demographics.age
        if (demographics.gender) updateData['demographics.gender'] = demographics.gender
        if (demographics.phone) updateData['demographics.phone'] = demographics.phone
        if (demographics.next_of_kin) {
            if (demographics.next_of_kin.name) updateData['demographics.next_of_kin.name'] = demographics.next_of_kin.name
            if (demographics.next_of_kin.relation) updateData['demographics.next_of_kin.relation'] = demographics.next_of_kin.relation
            if (demographics.next_of_kin.phone) updateData['demographics.next_of_kin.phone'] = demographics.next_of_kin.phone
        }
    }

    if (medical_history) {
        updateData.medical_history = medical_history
    }

    if (medical_config) {
        if (medical_config.therapy_drug) updateData['medical_config.therapy_drug'] = medical_config.therapy_drug
        if (medical_config.therapy_start_date) {
            const startDate = typeof medical_config.therapy_start_date === 'string' 
                ? new Date(medical_config.therapy_start_date) 
                : medical_config.therapy_start_date
            updateData['medical_config.therapy_start_date'] = startDate
        }
    }

    const updatedProfile = await PatientProfile.findByIdAndUpdate(
        user.profile_id,
        { $set: updateData },
        { new: true, runValidators: true }
    )

    if (!updatedProfile) {
        throw new ApiError(StatusCodes.NOT_FOUND, 'Patient profile not found')
    }

    res.status(StatusCodes.OK).json(
        new ApiResponse(StatusCodes.OK, 'Profile updated successfully', { profile: updatedProfile })
    )
})

export const updateHealthLogs = asyncHandler(async (req: Request<{}, {}, UpdateHealthLog["body"]>, res: Response) => {
	const { type, description } = req.body
	const { user_id } = req.user

	const user = await User.findById(user_id)
	const patientprofile = await PatientProfile.findByIdAndUpdate(user.profile_id,
		[{
			$set: {
				health_logs: {
					$concatArrays: [
						{ $filter: { input: "$health_logs", as: "log", cond: { $ne: ["$$log.type", type] } } },
						[{ type: type, description: description.trim(), date: new Date() }]
					]
				}
			}
		}],
		{ new: true, updatePipeline: true }
	);

	res.status(StatusCodes.OK).json(new ApiResponse(StatusCodes.OK, "Health Logs Updated Suucessfully"))
})

export const updateProfilePicture = async (req: Request, res: Response) => {
	if (!req.file) {
		throw new ApiError(StatusCodes.BAD_REQUEST, "Image is required for setting up profile picture")
	}
	const allowedMimeTypes = ['image/png', 'image/jpeg', 'image/jpg', 'image/webp']
	if (!allowedMimeTypes.includes(req.file.mimetype)) {
		throw new ApiError(StatusCodes.BAD_REQUEST, 'Invalid file type. Only PNG, JPEG, JPG, and WEBP images are allowed')
	}
	const { user_id } = req.user

	let fileUrl = ''
	try {
		fileUrl = await uploadFile("profiles", req.file)
	} catch (error) {
		logger.error("Error While Uploading profile to filebase", { error })
		throw new ApiError(StatusCodes.INSUFFICIENT_STORAGE, "Error While Uploading report to cloud")
	}

	const user = await User.findByIdAndUpdate(user_id, { profile_picture: fileUrl }, { new: true })
	res.status(StatusCodes.OK).json(new ApiResponse(StatusCodes.OK, "Profile Picture successfully changed"))
}

function parseDDMMYYYY(date: string | Date): Date {
	const regex = /^\d{2}-\d{2}-\d{4}$/
	if (date instanceof Date) return date
	if (typeof date !== 'string' || !regex.test(date)) {
		throw new ApiError(StatusCodes.BAD_REQUEST, 'Date must be in DD-MM-YYYY format')
	}
	const [day, month, year] = date.split('-').map(Number)
	return new Date(year, month - 1, day)
}

function formatDDMMYYYY(d: Date): string {
	const dd = `${d.getDate()}`.padStart(2, '0')
	const mm = `${d.getMonth() + 1}`.padStart(2, '0')
	const yyyy = d.getFullYear()
	return `${dd}-${mm}-${yyyy}`
}

function getMedicationDates(startDate: Date, weeklyDosage: Record<string, number>): string[] {
	const daysMap: Record<string, number> = {
		monday: 0,
		tuesday: 1,
		wednesday: 2,
		thursday: 3,
		friday: 4,
		saturday: 5,
		sunday: 6,
	}

	const targetDays = Object.entries(weeklyDosage)
		.filter(([, val]) => typeof val === 'number' && val > 0)
		.map(([day]) => daysMap[day])
		.filter((v) => v !== undefined)

	const start = startDate instanceof Date ? startDate : new Date(startDate)
	const today = new Date()
	const dates: string[] = []
	let current = new Date(start)

	while (current <= today) {
		if (targetDays.includes(current.getDay())) {
			dates.push(formatDDMMYYYY(current))
		}
		current.setDate(current.getDate() + 1)
	}

	return dates
}

function findMissedDoses(medicationDates: string[], takenDates: Array<Date | string | unknown>): string[] {
	const takenFormatted = new Set(
		(takenDates || []).map((d) => {
			const dt = d instanceof Date
				? d
				: typeof d === 'string' || typeof d === 'number'
					? new Date(d)
					: new Date(String(d))
			return formatDDMMYYYY(dt)
		})
	)

	const missed = medicationDates.filter((d) => !takenFormatted.has(d))
	missed.sort((a, b) => {
		const [ad, am, ay] = a.split('-').map(Number)
		const [bd, bm, by] = b.split('-').map(Number)
		return new Date(ay, am - 1, ad).getTime() - new Date(by, bm - 1, bd).getTime()
	})
	return missed
}


