import { StatusCodes } from "http-status-codes";

class ApiResponse{
    statusCode: StatusCodes
    data: any
    message: string
    success: boolean
    constructor(statusCode: StatusCodes,data:any,message="Success"){
        this.statusCode = statusCode;
        this.data = data;
        this.message = message;
        this.success = this.statusCode < 400;
    }
}

export default ApiResponse;