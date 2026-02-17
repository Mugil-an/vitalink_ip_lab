TODO: Add tests for patient file upload routes

The following patient routes require file upload functionality with filebase/S3:

1. POST /api/patient/reports (submitReport)
   - Requires file upload for INR report (PDF, PNG, JPEG)
   - Needs S3 upload functionality
   - Test file validation and upload

2. POST /api/patient/profile-pic (updateProfilePicture)
   - Requires image file upload
   - Validates file types (PNG, JPEG, JPG, WEBP)
   - Uploads to filebase

These routes need to be tested separately once filebase integration testing is setup with proper mocking or test buckets.
