import { StatusCodes } from "http-status-codes";

class ApiResponse{
    statusCode: StatusCodes
    data: any
    message: string
    success: boolean
    constructor(statusCode: StatusCodes,message="Success", data:any = null){
        this.statusCode = statusCode;
        this.data = data;
        this.message = message;
        this.success = this.statusCode < 400;
    }
}

export default ApiResponse;