TODO: Add tests for file upload routes

The following doctor routes require file upload functionality with filebase/S3:

1. GET /api/doctor/patients/:op_num/reports/:report_id (getReport)
   - Requires downloading report file from filebase
   - Need to mock S3 client or use test bucket

2. GET /api/doctor/profile (getProfile) 
   - Returns profile picture URL from filebase
   - Need to handle S3 download URL generation

3. POST /api/doctor/profile-pic (updateProfilePicture)
   - Requires multer file upload
   - Need to test file validation and S3 upload

These routes need to be tested separately once filebase integration testing is setup.
