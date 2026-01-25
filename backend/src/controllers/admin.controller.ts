import { Request, Response } from "express";
import { ApiError, ApiResponse, asyncHandler } from "@src/utils";
import { StatusCodes } from "http-status-codes";
import { DoctorProfile, User } from "@src/models";

export const createDoctor = asyncHandler(async (req: Request, res: Response) => {
  // TODO: Include Profile Picture Logic
  const { login_id, password, name, department, contact_number } = req.body;
  const doctorProfile = await DoctorProfile.create({ name, department, contact_number });
  const user = await User.create({})


})
