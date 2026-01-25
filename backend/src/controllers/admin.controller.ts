import { Request, Response } from "express";
import { ApiError, ApiResponse, asyncHandler } from "@src/utils";
import { StatusCodes } from "http-status-codes";
import { DoctorProfile, User, PatientProfile } from "@src/models";
import { UserType } from '@src/validators'
import type { createDoctorType, createPatientType, ReassignDoctorType, updateDoctorType, updatePatientType } from '@src/validators/admin.validator'

export const createDoctor = asyncHandler(async (req: Request<{}, {}, createDoctorType['body']>, res: Response) => {
  // TODO: Include Profile Picture Logic, conform password also
  const { login_id, password, name, department, contact_number } = req.body;

  const existingUser = await User.findOne({ login_id: login_id });
  if (existingUser) {
    throw new ApiError(StatusCodes.CONFLICT, "Login ID already exists");
  }

  const doctorProfile = await DoctorProfile.create({ name, department, contact_number });
  const user = await User.create({ login_id, user_type: UserType.DOCTOR, password, profile_id: doctorProfile._id })
  res.status(StatusCodes.CREATED).json(new ApiResponse(StatusCodes.CREATED, "Doctor created successfully", { doctor: doctorProfile }));
})

export const getAllDoctors = asyncHandler(async (req: Request, res: Response) => {
  const doctors = await User.find({ user_type: UserType.DOCTOR }).populate('profile_id');
  res.status(StatusCodes.OK).json(new ApiResponse(StatusCodes.OK, "Doctor Fetched Successfully", { doctors }))
})

export const getDoctorById = asyncHandler(async (req: Request, res: Response) => {
  const { id: login_id } = req.params
  const user = await User.findOne({ login_id, user_type: UserType.DOCTOR }).populate('profile_id')

  if (!user || !user.profile_id) {
    throw new ApiError(StatusCodes.NOT_FOUND, "Doctor not found")
  }

  res.status(StatusCodes.OK).json(new ApiResponse(StatusCodes.OK, "Doctor Returned successfully", { doctor: user }))
})

export const createPatient = asyncHandler(async (req: Request<{}, {}, createPatientType["body"]>, res: Response) => {
  const { assigned_doctor_id, op_num, name, password, age, gender, kin_name, kin_relation, kin_contact_number, } = req.body

  const existingUser = await User.findOne({ login_id: op_num })
  if (existingUser) {
    throw new ApiError(StatusCodes.OK, "Patient with OP_NUM already present");
  }

  const doctor = await User.findOne({ login_id: assigned_doctor_id, user_type: UserType.DOCTOR })
  if (!doctor) {
    throw new ApiError(StatusCodes.BAD_REQUEST, "Doctor Doesn't exist")
  }

  const patientProfile = await PatientProfile.create({
    assigned_doctor_id: doctor.profile_id,
    demographics: {
      name, age, gender, next_of_kin: { name: kin_name, relation: kin_relation, phone: kin_contact_number }
    }
  })

  const user = await User.create({ login_id: op_num, password, profile_id: patientProfile._id })

  res.status(StatusCodes.CREATED).json(new ApiResponse(StatusCodes.CREATED, "Patient Created Successfully", { ...patientProfile, ...doctor }))
})

export const listAllPatients = asyncHandler(async (req: Request, res: Response) => {
  const patients = await User.find({ user_type: UserType.PATIENT }).populate('profile_id')
  res.status(StatusCodes.OK).json(new ApiResponse(StatusCodes.OK, "Patient Fetched Successfully", { patients }))
})

export const getPatientById = asyncHandler(async (req: Request, res: Response) => {
  const { op_num: login_id } = req.params
  const user = await User.findOne({ login_id, user_type: UserType.PATIENT }).populate('profile_id')

  if (!user || !user.profile_id) {
    throw new ApiError(StatusCodes.NOT_FOUND, "Patient not found")
  }

  res.status(StatusCodes.OK).json(new ApiResponse(StatusCodes.OK, "Patient Fetched Successfully", { patient: user }))
})

export const updateDoctor = asyncHandler(
  async (req: Request<updateDoctorType['params'], {}, updateDoctorType['body']>, res: Response) => {
    const { id: login_id } = req.params
    const { name, password, department, contact_number } = req.body

    const user = await User.findOne({ login_id })
    if (!user || user.user_type !== UserType.DOCTOR) {
      throw new ApiError(StatusCodes.NOT_FOUND, "Doctor Not Found")
    }
    if (password) {
      user.password = password
      await user.save()
    }

    const profileUpdates: Record<string, unknown> = {}
    if (name !== undefined) profileUpdates.name = name
    if (department !== undefined) profileUpdates.department = department
    if (contact_number !== undefined) profileUpdates.contact_number = contact_number

    const doctor = await DoctorProfile.findByIdAndUpdate(user.profile_id, profileUpdates, { new: true })
    res.status(StatusCodes.OK).json(new ApiResponse(StatusCodes.OK, "Doctor Updated Successfully", { doctor }))
  })

export const updatePatient = asyncHandler(
  async (req: Request<updatePatientType['params'], {}, updatePatientType['body']>, res: Response) => {
    const { op_num: login_id } = req.params
    const { name, age, gender, password, kin_name, kin_relation, kin_contact_number, phone } = req.body

    const user = await User.findOne({ login_id, user_type: UserType.PATIENT })
    if (!user) {
      throw new ApiError(StatusCodes.NOT_FOUND, "Patient Not Found")
    }
    if (password) {
      user.password = password
      await user.save()
    }

    const profileUpdates: Record<string, unknown> = {}
    if (name !== undefined) profileUpdates['demographics.name'] = name
    if (age !== undefined) profileUpdates['demographics.age'] = age
    if (gender !== undefined) profileUpdates['demographics.gender'] = gender
    if (phone !== undefined) profileUpdates['demographics.phone'] = phone
    if (kin_name !== undefined) profileUpdates['demographics.next_of_kin.name'] = kin_name
    if (kin_relation !== undefined) profileUpdates['demographics.next_of_kin.relation'] = kin_relation
    if (kin_contact_number !== undefined) profileUpdates['demographics.next_of_kin.phone'] = kin_contact_number

    const patient = await PatientProfile.findByIdAndUpdate(user.profile_id, profileUpdates, { new: true })
    res.status(StatusCodes.OK).json(new ApiResponse(StatusCodes.OK, "Patient Updated Successfully", { patient }))
  })


export const reassignPatient = asyncHandler(async (req: Request<ReassignDoctorType['params'], {}, ReassignDoctorType['body']>, res: Response) => {
  const { op_num } = req.params;
  const { new_doctor_id } = req.body;

  const patient = await User.findOne({ login_id: op_num, user_type: UserType.PATIENT })
  if (!patient) {
    throw new ApiError(StatusCodes.BAD_REQUEST, `Patient with ${op_num}  Not Found`)
  }

  const doctor = await User.findOne({ login_id: new_doctor_id, user_type: UserType.DOCTOR });
  if (!doctor) {
    throw new ApiError(StatusCodes.BAD_REQUEST, "Doctor with The id not found")
  }

  const patientProfile = await PatientProfile.findByIdAndUpdate(patient.profile_id, { assigned_doctor_id: doctor.profile_id }, { new: true });

  res.status(StatusCodes.OK).json(new ApiResponse(StatusCodes.OK, "Doctor Reassigned Successfully", { patient: patientProfile }))
})

