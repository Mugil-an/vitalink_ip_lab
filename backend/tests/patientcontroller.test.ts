import axios, { AxiosInstance } from 'axios';
import { GenericContainer, StartedTestContainer } from 'testcontainers';
import mongoose from 'mongoose';
import app from '@alias/app';
import { User, DoctorProfile, PatientProfile } from '@alias/models';
import { Server } from 'http';

describe('Patient Routes', () => {
    let mongoContainer: StartedTestContainer;
    let server: Server;
    let api: AxiosInstance;
    let baseURL: string;
    let patientToken: string;
    let patientUser: any;
    let patientProfile: any;
    let doctorProfile: any;

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
            name: 'Dr. Test Doctor',
            department: 'Cardiology',
            contact_number: '1234567890'
        });

        const therapyStartDate = new Date('2024-01-01');
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
                therapy_start_date: therapyStartDate,
                target_inr: { min: 2.0, max: 3.0 }
            },
            weekly_dosage: {
                monday: 5,
                tuesday: 5,
                wednesday: 5,
                thursday: 5,
                friday: 5,
                saturday: 0,
                sunday: 0
            },
            medical_history: [{
                diagnosis: 'Atrial Fibrillation',
                duration_value: 2,
                duration_unit: 'Years'
            }]
        });

        patientUser = await User.create({
            login_id: 'patient001',
            password: 'patient123',
            user_type: 'PATIENT',
            profile_id: patientProfile._id,
            is_active: true
        });

        const patientLoginResponse = await api.post('/api/auth/login', {
            login_id: 'patient001',
            password: 'patient123'
        });
        patientToken = patientLoginResponse.data.data.token;
    }, 120000);

    afterAll(async () => {
        await mongoose.connection.dropDatabase();
        await mongoose.connection.close();
        await mongoContainer.stop();
        server.close();
    });

    describe('GET /api/patient/profile', () => {
        test('should get patient profile successfully', async () => {
            const response = await api.get('/api/patient/profile', {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.patient).toBeDefined();
            expect(response.data.data.patient.user_type).toBe('PATIENT');
            expect(response.data.data.patient.profile_id).toBeDefined();
            expect(response.data.data.patient.profile_id.demographics.name).toBe('Test Patient');
        });

        test('should include populated doctor profile', async () => {
            const response = await api.get('/api/patient/profile', {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.data.patient.profile_id.assigned_doctor_id).toBeDefined();
        });

        test('should fail without authentication', async () => {
            const response = await api.get('/api/patient/profile');

            expect(response.status).toBe(401);
            expect(response.data.success).toBe(false);
        });
    });

    describe('GET /api/patient/reports', () => {
        test('should get patient reports including INR history and health logs', async () => {
            const response = await api.get('/api/patient/reports', {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.report).toBeDefined();
            expect(response.data.data.report.inr_history).toBeDefined();
            expect(Array.isArray(response.data.data.report.inr_history)).toBe(true);
            expect(response.data.data.report.health_logs).toBeDefined();
            expect(response.data.data.report.weekly_dosage).toBeDefined();
            expect(response.data.data.report.medical_config).toBeDefined();
        });

        test('should fail without authentication', async () => {
            const response = await api.get('/api/patient/reports');

            expect(response.status).toBe(401);
            expect(response.data.success).toBe(false);
        });
    });

    describe('POST /api/patient/dosage', () => {
        test('should log dosage with valid DD-MM-YYYY date', async () => {
            const response = await api.post('/api/patient/dosage', {
                date: '15-02-2026'
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.patient.medical_config.taken_doses).toBeDefined();
            expect(Array.isArray(response.data.data.patient.medical_config.taken_doses)).toBe(true);
        });

        test('should add multiple dosages', async () => {
            await api.post('/api/patient/dosage', {
                date: '13-02-2026'
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            const response = await api.post('/api/patient/dosage', {
                date: '14-02-2026'
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.data.patient.medical_config.taken_doses.length).toBeGreaterThanOrEqual(2);
        });

        test('should fail with invalid date format', async () => {
            const response = await api.post('/api/patient/dosage', {
                date: '2026-02-15'
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
        });

        test('should fail with missing date', async () => {
            const response = await api.post('/api/patient/dosage', {}, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
        });

        test('should fail without authentication', async () => {
            const response = await api.post('/api/patient/dosage', {
                date: '15-02-2026'
            });

            expect(response.status).toBe(401);
            expect(response.data.success).toBe(false);
        });
    });

    describe('GET /api/patient/missed-doses', () => {
        beforeAll(async () => {
            await PatientProfile.findByIdAndUpdate(patientProfile._id, {
                'medical_config.taken_doses': []
            });
        });

        test('should calculate missed doses correctly with therapy start date', async () => {
            const response = await api.get('/api/patient/missed-doses', {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.recent_missed_doses).toBeDefined();
            expect(response.data.data.missed_doses).toBeDefined();
            expect(Array.isArray(response.data.data.recent_missed_doses)).toBe(true);
            expect(Array.isArray(response.data.data.missed_doses)).toBe(true);
        });

        test('should separate recent missed doses (last 7 days) from older ones', async () => {
            const response = await api.get('/api/patient/missed-doses', {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(200);
            const { recent_missed_doses, missed_doses } = response.data.data;

            recent_missed_doses.forEach((date: string) => {
                const [day, month, year] = date.split('-').map(Number);
                const dateObj = new Date(year, month - 1, day);
                const today = new Date();
                const sevenDaysAgo = new Date();
                sevenDaysAgo.setDate(today.getDate() - 7);

                expect(dateObj.getTime()).toBeLessThanOrEqual(today.getTime());
                expect(dateObj.getTime()).toBeGreaterThanOrEqual(sevenDaysAgo.getTime());
            });
        });

        test('should fail without therapy start date', async () => {
            const patientWithoutTherapy = await PatientProfile.create({
                assigned_doctor_id: doctorProfile._id,
                demographics: {
                    name: 'Patient Without Therapy',
                    age: 50,
                    gender: 'Female',
                    phone: '8888888888'
                },
                medical_config: {
                    target_inr: { min: 2.0, max: 3.0 }
                }
            });

            const userWithoutTherapy = await User.create({
                login_id: 'notherapy001',
                password: 'pass123',
                user_type: 'PATIENT',
                profile_id: patientWithoutTherapy._id,
                is_active: true
            });

            const loginResponse = await api.post('/api/auth/login', {
                login_id: 'notherapy001',
                password: 'pass123'
            });
            const token = loginResponse.data.data.token;

            const response = await api.get('/api/patient/missed-doses', {
                headers: { Authorization: `Bearer ${token}` }
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
            expect(response.data.message).toBe('Therapy start date or dosage schedule is missing');
        });

        test('should fail without dosage schedule', async () => {
            const patientNoDosage = await PatientProfile.create({
                assigned_doctor_id: doctorProfile._id,
                demographics: {
                    name: 'Patient No Dosage',
                    age: 55,
                    gender: 'Male',
                    phone: '7777777777'
                },
                medical_config: {
                    therapy_start_date: new Date('2024-01-01'),
                    target_inr: { min: 2.0, max: 3.0 }
                }
            });

            const userNoDosage = await User.create({
                login_id: 'nodosage001',
                password: 'pass123',
                user_type: 'PATIENT',
                profile_id: patientNoDosage._id,
                is_active: true
            });

            const loginResponse = await api.post('/api/auth/login', {
                login_id: 'nodosage001',
                password: 'pass123'
            });
            const token = loginResponse.data.data.token;

            const response = await api.get('/api/patient/missed-doses', {
                headers: { Authorization: `Bearer ${token}` }
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
        });

        test('should fail without authentication', async () => {
            const response = await api.get('/api/patient/missed-doses');

            expect(response.status).toBe(401);
            expect(response.data.success).toBe(false);
        });
    });

    describe('POST /api/patient/health-logs', () => {
        test('should add health log successfully', async () => {
            const response = await api.post('/api/patient/health-logs', {
                type: 'SIDE_EFFECT',
                description: 'Mild headache after medication'
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
        });

        test('should update existing health log of same type', async () => {
            await api.post('/api/patient/health-logs', {
                type: 'ILLNESS',
                description: 'Experiencing mild cold symptoms'
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            const response = await api.post('/api/patient/health-logs', {
                type: 'ILLNESS',
                description: 'Cold symptoms have improved'
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
        });

        test('should fail with invalid health log type', async () => {
            const response = await api.post('/api/patient/health-logs', {
                type: 'INVALID_TYPE',
                description: 'Test description'
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
        });

        test('should fail with missing type', async () => {
            const response = await api.post('/api/patient/health-logs', {
                description: 'Test description'
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
        });

        test('should fail with missing description', async () => {
            const response = await api.post('/api/patient/health-logs', {
                type: 'FEVER'
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
        });

        test('should fail without authentication', async () => {
            const response = await api.post('/api/patient/health-logs', {
                type: 'LIFESTYLE',
                description: 'Test'
            });

            expect(response.status).toBe(401);
            expect(response.data.success).toBe(false);
        });
    });

    describe('PUT /api/patient/profile', () => {
        test('should update patient name', async () => {
            const response = await api.put('/api/patient/profile', {
                demographics: {
                    name: 'Updated Patient Name'
                }
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.profile.demographics.name).toBe('Updated Patient Name');
        });

        test('should update patient age', async () => {
            const response = await api.put('/api/patient/profile', {
                demographics: {
                    age: 50
                }
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.profile.demographics.age).toBe(50);
        });

        test('should update patient gender', async () => {
            const response = await api.put('/api/patient/profile', {
                demographics: {
                    gender: 'Female'
                }
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.profile.demographics.gender).toBe('Female');
        });

        test('should update patient phone', async () => {
            const response = await api.put('/api/patient/profile', {
                demographics: {
                    phone: '5555555555'
                }
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.profile.demographics.phone).toBe('5555555555');
        });

        test('should update next of kin information', async () => {
            const response = await api.put('/api/patient/profile', {
                demographics: {
                    next_of_kin: {
                        name: 'Updated Kin',
                        relation: 'Child',
                        phone: '4444444444'
                    }
                }
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.profile.demographics.next_of_kin.name).toBe('Updated Kin');
            expect(response.data.data.profile.demographics.next_of_kin.relation).toBe('Child');
        });

        test('should update multiple demographics fields', async () => {
            const response = await api.put('/api/patient/profile', {
                demographics: {
                    name: 'Multi Update Patient',
                    age: 60,
                    phone: '3333333333'
                }
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.profile.demographics.name).toBe('Multi Update Patient');
            expect(response.data.data.profile.demographics.age).toBe(60);
            expect(response.data.data.profile.demographics.phone).toBe('3333333333');
        });

        test('should update medical history', async () => {
            const response = await api.put('/api/patient/profile', {
                medical_history: [
                    {
                        diagnosis: 'Hypertension',
                        duration_value: 5,
                        duration_unit: 'Years'
                    },
                    {
                        diagnosis: 'Type 2 Diabetes',
                        duration_value: 3,
                        duration_unit: 'Years'
                    }
                ]
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.profile.medical_history.length).toBe(2);
            expect(response.data.data.profile.medical_history[0].diagnosis).toBe('Hypertension');
        });

        test('should update multiple profile fields', async () => {
            const response = await api.put('/api/patient/profile', {
                demographics: {
                    name: 'Complete Update',
                    age: 65,
                    gender: 'Male'
                },
                medical_history: [{
                    diagnosis: 'Updated Condition',
                    duration_value: 1,
                    duration_unit: 'Years'
                }]
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.profile.demographics.name).toBe('Complete Update');
        });

        test('should fail with invalid gender', async () => {
            const response = await api.put('/api/patient/profile', {
                demographics: {
                    gender: 'InvalidGender'
                }
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
        });

        test('should fail with negative age', async () => {
            const response = await api.put('/api/patient/profile', {
                demographics: {
                    age: -5
                }
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
        });

        test('should fail with zero age', async () => {
            const response = await api.put('/api/patient/profile', {
                demographics: {
                    age: 0
                }
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
        });

        test('should fail with empty name', async () => {
            const response = await api.put('/api/patient/profile', {
                demographics: {
                    name: ''
                }
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
        });

        test('should fail when trying to update therapy_drug (doctor only)', async () => {
            const response = await api.put('/api/patient/profile', {
                medical_config: {
                    therapy_drug: 'Apixaban'
                }
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
        });

        test('should allow patient to update therapy_start_date', async () => {
            const newStartDate = new Date('2024-02-01T00:00:00Z');
            const response = await api.put('/api/patient/profile', {
                medical_config: {
                    therapy_start_date: newStartDate
                }
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
        });

        test('should fail when trying to update weekly_dosage (doctor only)', async () => {
            const response = await api.put('/api/patient/profile', {
                weekly_dosage: {
                    monday: 10,
                    tuesday: 10
                }
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
        });

        test('should fail with invalid duration unit', async () => {
            const response = await api.put('/api/patient/profile', {
                medical_history: [
                    {
                        diagnosis: 'Test',
                        duration_value: 5,
                        duration_unit: 'InvalidUnit'
                    }
                ]
            }, {
                headers: { Authorization: `Bearer ${patientToken}` }
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
        });

        test('should fail without authentication', async () => {
            const response = await api.put('/api/patient/profile', {
                demographics: {
                    name: 'Test'
                }
            });

            expect(response.status).toBe(401);
            expect(response.data.success).toBe(false);
        });
    });
});
