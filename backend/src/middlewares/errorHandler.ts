import mongoose from "mongoose";
import { Request, Response, NextFunction, ErrorRequestHandler } from "express";
import { ZodError } from "zod";
import ApiError from "../utils/ApiError";
import ApiResponse from "../utils/ApiResponse";
import { StatusCodes } from "http-status-codes";

const errorHandler: ErrorRequestHandler = (err: any, req: Request, res: Response, next: NextFunction) => {
  if (err instanceof ZodError) {
    const errors = err.issues.map((issue) => ({ message: issue.message }))
    return res.status(StatusCodes.BAD_REQUEST).json(new ApiResponse(StatusCodes.BAD_REQUEST, 'Validation failed', { errors }))
  }

  let error = err;
  if (!(err instanceof ApiError)) {
    console.log(error);
    const statusCode = error instanceof mongoose.Error ? StatusCodes.BAD_REQUEST : StatusCodes.INTERNAL_SERVER_ERROR
    const message = error.message || "Something went Wrong"
    error = new ApiError(statusCode, message)
  }

  const response = new ApiResponse(error.statusCode, error.message, error.data)
  return res.status(error.statusCode).json(response);
}

export default errorHandler
