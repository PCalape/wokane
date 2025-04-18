import {
  describe,
  it,
  expect,
  beforeAll,
  afterAll,
  beforeEach,
  jest,
} from '@jest/globals';
import { Test, TestingModule } from '@nestjs/testing';
import { JwtModule, JwtService } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { TestDatabaseSetup } from './test-db.setup';
import { AuthController } from '../src/auth/auth.controller';
import { AuthService } from '../src/auth/auth.service';
import { UsersModule } from '../src/users/users.module';
import { User, UserSchema } from '../src/users/user.entity';
import { JwtStrategy } from '../src/auth/strategies/jwt.strategy';
import { UsersService } from '../src/users/users.service';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';

describe('AuthController', () => {
  let app: INestApplication;
  let testDbSetup: TestDatabaseSetup;
  let usersService: UsersService;
  let authService: AuthService;

  beforeAll(async () => {
    testDbSetup = new TestDatabaseSetup();
    await testDbSetup.setupDatabase();

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [
        MongooseModule.forRoot(testDbSetup.getMongoUri()),
        MongooseModule.forFeature([{ name: User.name, schema: UserSchema }]),
        PassportModule.register({ defaultStrategy: 'jwt' }),
        JwtModule.register({
          secret: 'test-secret-key',
          signOptions: {
            expiresIn: '1h',
          },
        }),
        UsersModule,
        ConfigModule.forRoot({
          isGlobal: true,
          load: [
            () => ({
              JWT_SECRET: 'test-secret-key',
              JWT_EXPIRATION: 3600,
            }),
          ],
        }),
      ],
      controllers: [AuthController],
      providers: [
        AuthService,
        JwtStrategy,
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn((key: string) => {
              if (key === 'JWT_SECRET') return 'test-secret-key';
              if (key === 'JWT_EXPIRATION') return 3600;
              return null;
            }),
          },
        },
      ],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();

    usersService = moduleFixture.get<UsersService>(UsersService);
    authService = moduleFixture.get<AuthService>(AuthService);
  });

  afterAll(async () => {
    await app.close();
    await testDbSetup.closeDatabase();
  });

  beforeEach(async () => {
    await testDbSetup.clearDatabase();
  });

  describe('POST /auth/register', () => {
    it('should register a new user successfully', async () => {
      // Test data
      const registerDto = {
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
      };

      // Send request
      const response = await request(app.getHttpServer())
        .post('/auth/register')
        .send(registerDto)
        .expect(201);

      // Verify the user was created in the database
      const createdUser = await usersService.findByEmail(registerDto.email);
      expect(createdUser).toBeTruthy();
      expect(createdUser?.name).toBe(registerDto.name);
      expect(createdUser?.email).toBe(registerDto.email);
      // Password should be hashed, not stored in plain text
      expect(createdUser?.password).not.toBe(registerDto.password);
    });

    it('should not register a user with an existing email', async () => {
      // Create a user first
      const registerDto = {
        name: 'Test User',
        email: 'duplicate@example.com',
        password: 'password123',
      };

      await authService.register(registerDto);

      // Try to register with the same email
      await request(app.getHttpServer())
        .post('/auth/register')
        .send(registerDto)
        .expect(409); // Conflict status code
    });
  });

  describe('POST /auth/login', () => {
    it('should login successfully and return a JWT token', async () => {
      // Create a user first
      const registerDto = {
        name: 'Login Test User',
        email: 'login@example.com',
        password: 'password123',
      };

      await authService.register(registerDto);

      // Now try to login
      const loginDto = {
        email: 'login@example.com',
        password: 'password123',
      };

      const response = await request(app.getHttpServer())
        .post('/auth/login')
        .send(loginDto)
        .expect(201);

      // Should return a JWT token
      expect(response.body).toHaveProperty('accessToken');
      expect(typeof response.body.accessToken).toBe('string');
    });

    it('should not login with invalid credentials', async () => {
      // Create a user first
      const registerDto = {
        name: 'Invalid Login User',
        email: 'invalid@example.com',
        password: 'password123',
      };

      await authService.register(registerDto);

      // Try to login with wrong password
      const loginDto = {
        email: 'invalid@example.com',
        password: 'wrongpassword',
      };

      await request(app.getHttpServer())
        .post('/auth/login')
        .send(loginDto)
        .expect(401); // Unauthorized status code
    });
  });
});
