import { Request, Response } from 'express'
import { ApiError, ApiResponse, asyncHandler } from '@src/utils'
import { StatusCodes } from 'http-status-codes'
import { PatientProfile, User } from '@src/models'
import { UserType } from '@src/validators'

export const getPatients = asyncHandler(async (req: Request, res: Response) => {
  const { user_id } = req.user
  const patients = PatientProfile.find({ assigned_doctor: user_id })
  res.status(StatusCodes.OK).json(new ApiResponse(StatusCodes.OK, "Patients fetched successfully", { patients }))
})

export const viewPatient = asyncHandler(async (req: Request, res: Response) => {
  const { op_num } = req.params
  const patient = await PatientProfile.findOne({ login_id: op_num, assigned_doctor_id: req.user.user_id })
  if(!patient){
    throw new ApiError(StatusCodes.NOT_FOUND, "Patient not found")
  }
  res.status(StatusCodes.OK).json(new ApiResponse(StatusCodes.OK, "Patient fetched successfully", { patient }))
})

export const addPatient = asyncHandler(async (req: Request, res: Response) => {

})

export const reassignPatient = asyncHandler(async (req: Request, res: Response) => {

})

export const editPatientDosage = asyncHandler(async (req: Request, res: Response) => {

})

export const getReports = asyncHandler(async (req: Request, res: Response) => {

})

export const updateNextReview = asyncHandler(async (req: Request, res: Response) => {

})

export const addInstructions = asyncHandler(async (req: Request, res: Response) => {

})

export const getInstructions = asyncHandler(async (req: Request, res: Response) => {

})

export const getProfile = asyncHandler(async (req: Request, res: Response) => {
  
})

export const getDoctors = asyncHandler(async (req: Request, res: Response) => {
  const doctors = await User.find({ user_type: UserType.DOCTOR }).populate('profile_id', '-password -salt').lean()
  res.status(StatusCodes.OK).json(new ApiResponse(StatusCodes.OK, "Doctors fetched successfully", { doctors }))
})
