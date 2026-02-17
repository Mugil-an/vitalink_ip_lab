import axios, { AxiosInstance } from 'axios';
import { GenericContainer, StartedTestContainer } from 'testcontainers';
import mongoose from 'mongoose';
import app from '@alias/app';
import { User } from '@alias/models';
import AdminProfile from '@alias/models/adminprofile.schema';
import { Server } from 'http';

describe('Auth Routes', () => {
    let mongoContainer: StartedTestContainer;
    let server: Server;
    let api: AxiosInstance;
    let baseURL: string;
    let testUser: any;
    let testToken: string;

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

        const adminProfile = await AdminProfile.create({ permission: 'FULL_ACCESS' });

        testUser = await User.create({
            login_id: 'testuser',
            password: 'testpassword123',
            user_type: 'ADMIN',
            profile_id: adminProfile._id,
            is_active: true
        });
    }, 120000);

    afterAll(async () => {
        await mongoose.connection.dropDatabase();
        await mongoose.connection.close();
        await mongoContainer.stop();
        server.close();
    });

    describe('POST /api/auth/login', () => {
        test('should login successfully with valid credentials', async () => {
            const response = await api.post('/api/auth/login', {
                login_id: 'testuser',
                password: 'testpassword123'
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.token).toBeDefined();
            expect(response.data.data.user).toBeDefined();
            expect(response.data.data.user.login_id).toBe('testuser');
            testToken = response.data.data.token;
        });

        test('should fail with invalid login_id', async () => {
            const response = await api.post('/api/auth/login', {
                login_id: 'nonexistentuser',
                password: 'testpassword123'
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
            expect(response.data.message).toBe("User Doesn't exist");
        });

        test('should fail with invalid password', async () => {
            const response = await api.post('/api/auth/login', {
                login_id: 'testuser',
                password: 'wrongpassword'
            });

            expect(response.status).toBe(401);
            expect(response.data.success).toBe(false);
            expect(response.data.message).toBe('Invalid credentials');
        });

        test('should fail with inactive user account', async () => {
            await User.findByIdAndUpdate(testUser._id, { is_active: false });

            const response = await api.post('/api/auth/login', {
                login_id: 'testuser',
                password: 'testpassword123'
            });

            expect(response.status).toBe(403);
            expect(response.data.success).toBe(false);
            expect(response.data.message).toBe('Account is inactive. Please contact administrator.');

            await User.findByIdAndUpdate(testUser._id, { is_active: true });
        });

        test('should fail with missing login_id', async () => {
            const response = await api.post('/api/auth/login', {
                password: 'testpassword123'
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
        });

        test('should fail with missing password', async () => {
            const response = await api.post('/api/auth/login', {
                login_id: 'testuser'
            });

            expect(response.status).toBe(400);
            expect(response.data.success).toBe(false);
        });
    });

    describe('POST /api/auth/logout', () => {
        test('should logout successfully with valid token', async () => {
            const loginResponse = await api.post('/api/auth/login', {
                login_id: 'testuser',
                password: 'testpassword123'
            });
            const token = loginResponse.data.data.token;

            const response = await api.post('/api/auth/logout', {}, {
                headers: { Authorization: `Bearer ${token}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.message).toBe('Logout successful. Please clear the token from client-side.');
        });

        test('should fail without authentication token', async () => {
            const response = await api.post('/api/auth/logout');

            expect(response.status).toBe(401);
            expect(response.data.success).toBe(false);
        });

        test('should fail with invalid token', async () => {
            const response = await api.post('/api/auth/logout', {}, {
                headers: { Authorization: 'Bearer invalidtoken123' }
            });

            expect(response.status).toBe(401);
            expect(response.data.success).toBe(false);
        });
    });

    describe('GET /api/auth/me', () => {
        test('should get user profile successfully with valid token', async () => {
            const loginResponse = await api.post('/api/auth/login', {
                login_id: 'testuser',
                password: 'testpassword123'
            });
            const token = loginResponse.data.data.token;

            const response = await api.get('/api/auth/me', {
                headers: { Authorization: `Bearer ${token}` }
            });

            expect(response.status).toBe(200);
            expect(response.data.success).toBe(true);
            expect(response.data.data.user).toBeDefined();
            expect(response.data.data.user.login_id).toBe('testuser');
            expect(response.data.data.user.password).toBeUndefined();
            expect(response.data.data.user.salt).toBeUndefined();
        });

        test('should fail without authentication token', async () => {
            const response = await api.get('/api/auth/me');

            expect(response.status).toBe(401);
            expect(response.data.success).toBe(false);
        });

        test('should fail with invalid token', async () => {
            const response = await api.get('/api/auth/me', {
                headers: { Authorization: 'Bearer invalidtoken123' }
            });

            expect(response.status).toBe(401);
            expect(response.data.success).toBe(false);
        });
    });
});