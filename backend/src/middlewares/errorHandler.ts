import mongoose from "mongoose";
import ApiError from "../utils/ApiError";
import { Request, Response, NextFunction, ErrorRequestHandler } from "express";


const errorHandler: ErrorRequestHandler = (err: any, req: Request, res: Response, next: NextFunction) => {
  let error = err;
  if (!(err instanceof ApiError)) {
    console.log(error);
    const statusCode = error instanceof mongoose.Error ? 400 : 500
    const message = error.message || "Something went Wrong"
    error = new ApiError(statusCode, message)
  }
  const response = { ...error }
  return res.status(error.statusCode).json(response);
}

export default errorHandler
