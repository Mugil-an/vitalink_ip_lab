import axios, { AxiosInstance } from 'axios';
import { GenericContainer, StartedTestContainer } from 'testcontainers';
import mongoose from 'mongoose';
import app from '@alias/app';
import { User, DoctorProfile, PatientProfile } from '@alias/models';
import { Server } from 'http';

describe('Doctor Routes', () => {
    let mongoContainer: StartedTestContainer;
    let server: Server;
    let api: AxiosInstance;
    let baseURL: string;
    let doctorToken: string;
    let doctorUser: any;
    let doctorProfile: any;
    let secondDoctorToken: string;
    let secondDoctorUser: any;
    let patientUser: any;
    let patientProfile: any;

    beforeAll(async () => {
        mongoContainer = await new GenericContainer('mongo:7.0')
            .withExposedPorts(27017)
            .start();
        const mongoUri = `mongodb://${mongoContainer.getHost()}:${mongoContainer.getMappedPort(27017)}/test`;
        await mongoose.connect(mongoUri);

        server = app.listen(0);
        const address = server.address();
        const port = typeof address === 'object' && address !== null ? address.port : 3000;
        baseURL = `http://localhost:${port}`;
        api = axios.create({ baseURL, validateStatus: () => true });

        doctorProfile = await DoctorProfile.create({
            name: 'Dr. John Doe',
            department: 'Cardiology',
            contact_number: '1234567890'
        });

        doctorUser = await User.create({
            login_id: 'doctor001',
            password: 'doctor123',
            user_type: 'DOCTOR',
            profile_id: doctorProfile._id,
            is_active: true
        });

        const secondDoctorProfile = await DoctorProfile.create({
            name: 'Dr. Jane Smith',
            department: 'Neurology',
            contact_number: '0987654321'
        });

        secondDoctorUser = await User.create({
            login_id: 'doctor002',
            password: 'doctor456',
            user_type: 'DOCTOR',
            profile_id: secondDoctorProfile._id,
            is_active: true
        });

        patientProfile = await PatientProfile.create({
            assigned_doctor_id: doctorProfile._id,
            demographics: {
                name: 'Test Patient',
                age: 45,
                gender: 'Male',
                phone: '9876543210',
                next_of_kin: {
                    name: 'Emergency Contact',
                    relation: 'Spouse',
                    phone: '9876543211'
                }
            },
            medical_config: {
                therapy_drug: 'Warfarin',
                therapy_start_date: new Date('2024-01-01'),
                target_inr: { min: 2.0, max: 3.0 }
            },
            weekly_dosage: {
                monday: 5,
                tuesday: 5,
                wednesday: 5,
                thursday: 5,
                friday: 5,
                saturday: 5,
                sunday: 5
            }
        });

        patientUser = await User.create({
            login_id: 'PAT001',
            password: '9876543210',
            user_type: 'PATIENT',
            profile_id: patientProfile._id,
            is_active: true
        });

        const doctorLoginResponse = await api.post('/api/auth/login', {
            login_id: 'doctor001',
            password: 'doctor123'
        });
        doctorToken = doctorLoginResponse.data.data.token;

        const secondDoctorLoginResponse = await api.post('/api/auth/login', {
            login_id: 'doctor002',
            password: 'doctor456'
        });
        secondDoctorToken = secondDoctorLoginResponse.data.data.token;
    }, 120000);

    afterAll(async () => {
        await mongoose.connection.dropDatabase();
        await mongoose.connection.close();
        await mongoContainer.stop();
        server.close();
    });

    describe('GET /api/doctors/patients', () => {
        test('should get all patients assigned to doctor', async () => {
            const response = await api.get('/api/doctors/patients', {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.patients).toBeDefined();
            expect(Array.isArray(response.data.data.patients)).toBe(true);
            expect(response.data.data.patients.length).toBeGreaterThan(0);
            expect(response.data.data.patients[0].login_id).toBe('PAT001');
        });

        test('should return empty array if doctor has no patients', async () => {
            const response = await api.get('/api/doctors/patients', {
                headers: { Authorization: `Bearer ${secondDoctorToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.patients).toBeDefined();
            expect(Array.isArray(response.data.data.patients)).toBe(true);
            expect(response.data.data.patients.length).toBe(0);
        });

        test('should fail without authentication token', async () => {
            const response = await api.get('/api/doctors/patients');

            expect(response.status).toBe(401);
            expect(response.data.success).toBe(false);
        });

        test('should fail with invalid token', async () => {
            const response = await api.get('/api/doctors/patients', {
                headers: { Authorization: 'Bearer invalidtoken123' }
            });

            expect(response.status).toBe(401);
            expect(response.data.success).toBe(false);
        });
    });

    describe('GET /api/doctors/patients/:op_num', () => {
        test('should get specific patient by op_num', async () => {
            const response = await api.get('/api/doctors/patients/PAT001', {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.patient).toBeDefined();
            expect(response.data.data.patient.demographics.name).toBe('Test Patient');
        });

        test('should fail with non-existent op_num', async () => {
            const response = await api.get('/api/doctors/patients/INVALID001', {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(404);
            expect(response.data.success).toBe(false);
            expect(response.data.message).toBe('Patient not found');
        });

        test('should fail without authentication', async () => {
            const response = await api.get('/api/doctors/patients/PAT001');

            expect(response.status).toBe(401);
            expect(response.data.success).toBe(false);
        });
    });

    describe('POST /api/doctors/patients', () => {
        test('should create new patient with all required fields', async () => {
            const newPatient = {
                name: 'New Patient',
                op_num: 'PAT002',
                age: 50,
                gender: 'Female',
                contact_no: '8888888888',
                target_inr_min: 2.5,
                target_inr_max: 3.5,
                therapy: 'Warfarin',
                therapy_start_date: '2024-01-15',
                prescription: {
                    monday: 4,
                    tuesday: 4,
                    wednesday: 4,
                    thursday: 4,
                    friday: 4,
                    saturday: 4,
                    sunday: 4
                },
                medical_history: [{
                    diagnosis: 'Atrial Fibrillation',
                    duration_value: 2,
                    duration_unit: 'Years'
                }],
                kin_name: 'Family Contact',
                kin_relation: 'Sibling',
                kin_contact_number: '7777777777'
            };

            const response = await api.post('/api/doctors/patients', newPatient, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(201);
            expect(response.data.success).toBe(true);
            expect(response.data.data.patient).toBeDefined();
            expect(response.data.data.patient.demographics.name).toBe('New Patient');
        });

        test('should create patient with minimum required fields', async () => {
            const minimalPatient = {
                name: 'Minimal Patient',
                op_num: 'PAT003',
                gender: 'Male',
                contact_no: '7777777777',
                kin_contact_number: '6666666666'
            };

            const response = await api.post('/api/doctors/patients', minimalPatient, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(201);
            expect(response.data.success).toBe(true);
            expect(response.data.data.patient).toBeDefined();
        });

        test('should fail with duplicate op_num', async () => {
            const duplicatePatient = {
                name: 'Duplicate Patient',
                op_num: 'PAT001',
                gender: 'Male',
                contact_no: '5555555555',
                kin_contact_number: '4444444444'
            };

            const response = await api.post('/api/doctors/patients', duplicatePatient, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(409);
            expect(response.data.success).toBe(false);
            expect(response.data.message).toBe('Patient with this OP number already exists');
        });

        test('should fail with missing required field - name', async () => {
            const invalidPatient = {
                op_num: 'PAT004',
                gender: 'Male',
                contact_no: '3333333333',
                kin_contact_number: '2222222222'
            };

            const response = await api.post('/api/doctors/patients', invalidPatient, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
        });

        test('should fail with missing required field - op_num', async () => {
            const invalidPatient = {
                name: 'No OP Patient',
                gender: 'Male',
                contact_no: '3333333333',
                kin_contact_number: '2222222222'
            };

            const response = await api.post('/api/doctors/patients', invalidPatient, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
        });

        test('should fail with invalid gender', async () => {
            const invalidPatient = {
                name: 'Invalid Gender Patient',
                op_num: 'PAT005',
                gender: 'InvalidGender',
                contact_no: '3333333333',
                kin_contact_number: '2222222222'
            };

            const response = await api.post('/api/doctors/patients', invalidPatient, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
        });

        test('should fail with invalid contact_no length', async () => {
            const invalidPatient = {
                name: 'Invalid Contact Patient',
                op_num: 'PAT006',
                gender: 'Male',
                contact_no: '123',
                kin_contact_number: '2222222222'
            };

            const response = await api.post('/api/doctors/patients', invalidPatient, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
        });

        test('should fail without authentication', async () => {
            const newPatient = {
                name: 'Unauthorized Patient',
                op_num: 'PAT007',
                gender: 'Male',
                contact_no: '1111111111',
                kin_contact_number: '0000000000'
            };

            const response = await api.post('/api/doctors/patients', newPatient);

            expect(response.status).toBe(401);
            expect(response.data.success).toBe(false);
        });
    });

    describe('PATCH /api/doctors/patients/:op_num/reassign', () => {
        test('should reassign patient to another doctor', async () => {
            const response = await api.patch('/api/doctors/patients/PAT001/reassign', {
                new_doctor_id: 'doctor002'
            }, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.patient).toBeDefined();

            const updatedPatient = await PatientProfile.findById(patientProfile._id);
            expect(updatedPatient.assigned_doctor_id.toString()).toBe(secondDoctorUser.profile_id.toString());

            await PatientProfile.findByIdAndUpdate(patientProfile._id, {
                assigned_doctor_id: doctorProfile._id
            });
        });

        test('should fail with non-existent patient', async () => {
            const response = await api.patch('/api/doctors/patients/INVALID001/reassign', {
                new_doctor_id: 'doctor002'
            }, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(404);
            expect(response.data.success).toBe(false);
            expect(response.data.message).toBe('Patient not found');
        });

        test('should fail with non-existent target doctor', async () => {
            const response = await api.patch('/api/doctors/patients/PAT001/reassign', {
                new_doctor_id: 'invalid_doctor'
            }, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
            expect(response.data.message).toBe('Target doctor not found');
        });

        test('should fail without authentication', async () => {
            const response = await api.patch('/api/doctors/patients/PAT001/reassign', {
                new_doctor_id: 'doctor002'
            });

            expect(response.status).toBe(401);
            expect(response.data.success).toBe(false);
        });
    });

    describe('PUT /api/doctors/patients/:op_num/dosage', () => {
        test('should update patient dosage successfully', async () => {
            const newDosage = {
                monday: 6,
                tuesday: 6,
                wednesday: 6,
                thursday: 6,
                friday: 6,
                saturday: 6,
                sunday: 6
            };

            const response = await api.put('/api/doctors/patients/PAT001/dosage', {
                prescription: newDosage
            }, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.patient).toBeDefined();
            expect(response.data.data.patient.weekly_dosage.monday).toBe(6);
        });

        test('should update partial dosage schedule', async () => {
            const partialDosage = {
                monday: 7,
                friday: 7
            };

            const response = await api.put('/api/doctors/patients/PAT001/dosage', {
                prescription: partialDosage
            }, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
        });

        test('should fail with non-existent patient', async () => {
            const response = await api.put('/api/doctors/patients/INVALID001/dosage', {
                prescription: { monday: 5 }
            }, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(404);
            expect(response.data.success).toBe(false);
            expect(response.data.message).toBe('Patient not found');
        });

        test('should fail without authentication', async () => {
            const response = await api.put('/api/doctors/patients/PAT001/dosage', {
                prescription: { monday: 5 }
            });

            expect(response.status).toBe(401);
            expect(response.data.success).toBe(false);
        });
    });

    describe('GET /api/doctors/patients/:op_num/reports', () => {
        test('should get patient INR reports', async () => {
            const response = await api.get('/api/doctors/patients/PAT001/reports', {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.inr_history).toBeDefined();
            expect(Array.isArray(response.data.data.inr_history)).toBe(true);
        });

        test('should fail with non-existent patient', async () => {
            const response = await api.get('/api/doctors/patients/INVALID001/reports', {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(404);
            expect(response.data.success).toBe(false);
        });

        test('should fail without authentication', async () => {
            const response = await api.get('/api/doctors/patients/PAT001/reports');

            expect(response.status).toBe(401);
            expect(response.data.success).toBe(false);
        });
    });

    describe('PUT /api/doctors/patients/:op_num/reports/:report_id', () => {
        let reportId: string;

        beforeAll(async () => {
            const patient = await PatientProfile.findById(patientProfile._id);
            patient.inr_history.push({
                test_date: new Date('2024-01-15'),
                inr_value: 2.5,
                is_critical: false,
                file_url: 'test-file-url',
                notes: 'Initial test'
            });
            await patient.save();
            reportId = patient.inr_history[patient.inr_history.length - 1]._id.toString();
        });

        test('should update report notes', async () => {
            const response = await api.put(`/api/doctors/patients/PAT001/reports/${reportId}`, {
                notes: 'Updated notes for the report'
            }, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.report.notes).toBe('Updated notes for the report');
        });

        test('should update report critical status', async () => {
            const response = await api.put(`/api/doctors/patients/PAT001/reports/${reportId}`, {
                is_critical: true
            }, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.report.is_critical).toBe(true);
        });

        test('should update both notes and critical status', async () => {
            const response = await api.put(`/api/doctors/patients/PAT001/reports/${reportId}`, {
                notes: 'Critical patient attention needed',
                is_critical: true
            }, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.report.notes).toBe('Critical patient attention needed');
            expect(response.data.data.report.is_critical).toBe(true);
        });

        test('should fail with invalid report_id format', async () => {
            const response = await api.put('/api/doctors/patients/PAT001/reports/invalid_id', {
                notes: 'Test'
            }, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect([400, 404]).toContain(response.status);
            expect(response.data.success).toBe(false);
        });

        test('should fail with non-existent report_id', async () => {
            const fakeId = new mongoose.Types.ObjectId().toString();
            const response = await api.put(`/api/doctors/patients/PAT001/reports/${fakeId}`, {
                notes: 'Test'
            }, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(404);
            if (response.data.success !== undefined) {
                expect(response.data.success).toBe(false);
            }
        });

        test('should fail without authentication', async () => {
            const response = await api.put(`/api/doctors/patients/PAT001/reports/${reportId}`, {
                notes: 'Test'
            });

            expect([401, 404]).toContain(response.status);
            if (response.data.success !== undefined) {
                expect(response.data.success).toBe(false);
            }
        });
    });

    describe('PUT /api/doctors/patients/:op_num/config', () => {
        test('should update next review date with valid DD-MM-YYYY format', async () => {
            const response = await api.put('/api/doctors/patients/PAT001/config', {
                date: '15-03-2024'
            }, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.patient).toBeDefined();
        });

        test('should fail with invalid date format', async () => {
            const response = await api.put('/api/doctors/patients/PAT001/config', {
                date: '2024-03-15'
            }, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
            expect(response.data.message).toBe('Date must be in DD-MM-YYYY format');
        });

        test('should fail with non-string date', async () => {
            const response = await api.put('/api/doctors/patients/PAT001/config', {
                date: 12345
            }, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
        });

        test('should fail with non-existent patient', async () => {
            const response = await api.put('/api/doctors/patients/INVALID001/config', {
                date: '15-03-2024'
            }, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(404);
            expect(response.data.success).toBe(false);
        });

        test('should fail without authentication', async () => {
            const response = await api.put('/api/doctors/patients/PAT001/config', {
                date: '15-03-2024'
            });

            expect(response.status).toBe(401);
            expect(response.data.success).toBe(false);
        });
    });

    describe('PUT /api/doctors/profile', () => {
        test('should update doctor name', async () => {
            const response = await api.put('/api/doctors/profile', {
                name: 'Dr. John Updated'
            }, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);

            const updated = await DoctorProfile.findById(doctorProfile._id);
            expect(updated.name).toBe('Dr. John Updated');
        });

        test('should update doctor department', async () => {
            const response = await api.put('/api/doctors/profile', {
                department: 'Neurology'
            }, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);

            const updated = await DoctorProfile.findById(doctorProfile._id);
            expect(updated.department).toBe('Neurology');
        });

        test('should update doctor contact number', async () => {
            const response = await api.put('/api/doctors/profile', {
                contact_number: '9999999999'
            }, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);

            const updated = await DoctorProfile.findById(doctorProfile._id);
            expect(updated.contact_number).toBe('9999999999');
        });

        test('should update multiple fields at once', async () => {
            const response = await api.put('/api/doctors/profile', {
                name: 'Dr. John Doe',
                department: 'Cardiology',
                contact_number: '1234567890'
            }, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
        });

        test('should fail with invalid contact_number length', async () => {
            const response = await api.put('/api/doctors/profile', {
                contact_number: '123'
            }, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
        });

        test('should fail with empty name', async () => {
            const response = await api.put('/api/doctors/profile', {
                name: ''
            }, {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
        });

        test('should fail without authentication', async () => {
            const response = await api.put('/api/doctors/profile', {
                name: 'Test'
            });

            expect(response.status).toBe(401);
            expect(response.data.success).toBe(false);
        });
    });

    describe('GET /api/doctors/doctors', () => {
        test('should get all doctors', async () => {
            const response = await api.get('/api/doctors/doctors', {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.doctors).toBeDefined();
            expect(Array.isArray(response.data.data.doctors)).toBe(true);
            expect(response.data.data.doctors.length).toBeGreaterThanOrEqual(2);
        });

        test('should not include password or salt in doctor data', async () => {
            const response = await api.get('/api/doctors/doctors', {
                headers: { Authorization: `Bearer ${doctorToken}` }
            });

            expect(response.status).toBe(200);
            response.data.data.doctors.forEach((doctor: any) => {
                expect(doctor.password).toBeUndefined();
                expect(doctor.salt).toBeUndefined();
            });
        });

        test('should fail without authentication', async () => {
            const response = await api.get('/api/doctors/doctors');

            expect(response.status).toBe(401);
            expect(response.data.success).toBe(false);
        });
    });
});

