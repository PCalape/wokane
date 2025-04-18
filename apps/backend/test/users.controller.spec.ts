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
import { UsersController } from '../src/users/users.controller';
import { UsersService } from '../src/users/users.service';
import { User, UserSchema } from '../src/users/user.entity';
import { JwtStrategy } from '../src/auth/strategies/jwt.strategy';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';

describe('UsersController', () => {
  let app: INestApplication;
  let testDbSetup: TestDatabaseSetup;
  let usersService: UsersService;
  let jwtToken: string;
  let userId: string;
  let jwtService: JwtService;
  let userEmail: string; // Add this variable to store the dynamic email

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
      controllers: [UsersController],
      providers: [
        UsersService,
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
    jwtService = moduleFixture.get<JwtService>(JwtService);
  });

  afterAll(async () => {
    await app.close();
    await testDbSetup.closeDatabase();
  });

  beforeEach(async () => {
    // Perform a complete database reset
    await testDbSetup.clearDatabase();

    // Create a test user with unique email
    const timestamp = Date.now();
    userEmail = `test${timestamp}@example.com`; // Store the email
    const createUserDto = {
      name: 'Test User',
      email: userEmail,
      password: 'password123',
    };
    await usersService.createUser(createUserDto);

    // Find the user
    const user = await usersService.findByEmail(userEmail);
    if (user) {
      // Add proper type assertion for MongoDB document
      userId = (user as any)._id.toString();

      // Generate a JWT token for authentication
      jwtToken = jwtService.sign(
        { id: userId, email: userEmail },
        { secret: 'test-secret-key' }
      );
    }
  });

  describe('GET /users', () => {
    it('should return all users when authenticated', async () => {
      const response = await request(app.getHttpServer())
        .get('/users')
        .set('Authorization', `Bearer ${jwtToken}`)
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBe(1);
      expect(response.body[0].email).toBe(userEmail); // Use the stored email
    });

    it('should not allow access without authentication', async () => {
      await request(app.getHttpServer()).get('/users').expect(401);
    });
  });

  describe('GET /users/:id', () => {
    it('should return a specific user when authenticated', async () => {
      const response = await request(app.getHttpServer())
        .get(`/users/${userId}`)
        .set('Authorization', `Bearer ${jwtToken}`)
        .expect(200);

      expect(response.body).toBeDefined();
      expect(response.body.email).toBe(userEmail); // Use the stored email
      expect(response.body.name).toBe('Test User');
    });

    it('should not allow access without authentication', async () => {
      await request(app.getHttpServer()).get(`/users/${userId}`).expect(401);
    });
  });

  describe('PUT /users/:id', () => {
    it('should update a user when authenticated', async () => {
      const updateDto = { name: 'Updated User Name' };

      const response = await request(app.getHttpServer())
        .put(`/users/${userId}`)
        .set('Authorization', `Bearer ${jwtToken}`)
        .send(updateDto)
        .expect(200);

      expect(response.body).toBeDefined();
      expect(response.body.name).toBe('Updated User Name');
      expect(response.body.email).toBe(userEmail); // Use the stored email

      // Verify the update in the database
      const updatedUser = await usersService.findOne(userId);
      expect(updatedUser?.name).toBe('Updated User Name');
    });

    it('should not allow access without authentication', async () => {
      const updateDto = { name: 'Updated User Name' };

      await request(app.getHttpServer())
        .put(`/users/${userId}`)
        .send(updateDto)
        .expect(401);
    });
  });

  describe('DELETE /users/:id', () => {
    it('should delete a user when authenticated', async () => {
      await request(app.getHttpServer())
        .delete(`/users/${userId}`)
        .set('Authorization', `Bearer ${jwtToken}`)
        .expect(200);

      // Verify the user was deleted
      const deletedUser = await usersService.findOne(userId);
      expect(deletedUser).toBeNull();
    });

    it('should not allow access without authentication', async () => {
      await request(app.getHttpServer()).delete(`/users/${userId}`).expect(401);
    });
  });
});
