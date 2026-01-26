import { Request, Response } from 'express'
import { StatusCodes } from 'http-status-codes'
import { asyncHandler, ApiError, ApiResponse, generateToken } from '@src/utils'
import {User} from '@src/models'
import { comparePasswords } from '@src/utils'
import { UserType } from '@src/validators'
import { LoginInput } from '@src/validators/user.validator'


export const loginController = asyncHandler(async (req: Request<{}, {} , LoginInput["body"]>, res: Response) => {
  const { login_id, password } = req.body;
  const user = await User.findOne({ login_id })
  if (!user) {
    throw new ApiError(StatusCodes.BAD_REQUEST, "User Doesn't exist")
  }
  if (!user.is_active) {
    throw new ApiError(StatusCodes.FORBIDDEN, 'Account is inactive. Please contact administrator.')
  }

  const isPasswordValid = await comparePasswords({
      password,
      salt: user.salt,
      hashedPassword: user.password,
  })

  if(!isPasswordValid){
    throw new ApiError(StatusCodes.UNAUTHORIZED, 'Invalid credentials')
  }

  const token = generateToken({user_id: user._id.toString(), user_type: user.user_type as UserType})

  res.status(StatusCodes.OK).json(new ApiResponse(StatusCodes.OK, "User Logined In Successfully", {token, user}))
})

export const logoutController = asyncHandler((req: Request, res: Response) => {
   res.status(StatusCodes.OK).json({
      success: true,
      message: 'Logout successful. Please clear the token from client-side.',
   })
})

export const getMeController = asyncHandler(async (req: Request, res: Response) => {
    if (!req.user) {
        throw new ApiError(StatusCodes.UNAUTHORIZED, 'User not authenticated')
    }

    const user = await User.findById(req.user.user_id).populate('profile_id').select('-password -salt').lean()
    if (!user) {
        throw new ApiError(StatusCodes.NOT_FOUND, 'User not found')
    }

    res.status(StatusCodes.OK).json(new ApiResponse(StatusCodes.OK, 'User profile retrieved successfully', { user }))
})