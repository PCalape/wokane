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
import { ExpensesController } from '../src/expenses/expenses.controller';
import { ExpensesService } from '../src/expenses/expenses.service';
import {
  Expense,
  ExpenseSchema,
} from '../src/expenses/entities/expense.entity';
import { User, UserSchema } from '../src/users/user.entity';
import { JwtStrategy } from '../src/auth/strategies/jwt.strategy';
import { UsersService } from '../src/users/users.service';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { TestDatabaseSetup } from './test-db.setup';

describe('ExpensesController', () => {
  let app: INestApplication;
  let testDbSetup: TestDatabaseSetup;
  let expensesService: ExpensesService;
  let usersService: UsersService;
  let jwtToken: string;
  let userId: string;
  let expenseId: string;
  let jwtService: JwtService;

  beforeAll(async () => {
    testDbSetup = new TestDatabaseSetup();
    await testDbSetup.setupDatabase();

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [
        MongooseModule.forRoot(testDbSetup.getMongoUri()),
        MongooseModule.forFeature([
          { name: Expense.name, schema: ExpenseSchema },
          { name: User.name, schema: UserSchema },
        ]),
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
      controllers: [ExpensesController],
      providers: [
        ExpensesService,
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

    expensesService = moduleFixture.get<ExpensesService>(ExpensesService);
    usersService = moduleFixture.get<UsersService>(UsersService);
    jwtService = moduleFixture.get<JwtService>(JwtService);
  });

  afterAll(async () => {
    await app.close();
    await testDbSetup.closeDatabase();
  });

  beforeEach(async () => {
    await testDbSetup.clearDatabase();

    // Create a test user with unique email
    const timestamp = Date.now();
    const createUserDto = {
      name: 'Test User',
      email: `test${timestamp}@example.com`,
      password: 'password123',
    };
    await usersService.createUser(createUserDto);

    // Find the user
    const user = await usersService.findByEmail(`test${timestamp}@example.com`);
    if (user) {
      userId = (user as any)._id.toString();

      // Generate a JWT token for authentication
      jwtToken = jwtService.sign(
        { id: userId, email: `test${timestamp}@example.com` },
        { secret: 'test-secret-key' }
      );
    }

    // Create a test expense
    const createExpenseDto = {
      title: 'Test Expense',
      amount: 99.99,
      date: new Date(),
    };
    const createdExpense = await expensesService.create(createExpenseDto);
    expenseId = (createdExpense as any)._id.toString();
  });

  describe('GET /expenses', () => {
    it('should return all expenses when authenticated', async () => {
      const response = await request(app.getHttpServer())
        .get('/expenses')
        .set('Authorization', `Bearer ${jwtToken}`)
        .expect(200);

      expect(Array.isArray(response.body)).toBe(true);
      expect(response.body.length).toBe(1);
      expect(response.body[0].title).toBe('Test Expense');
      expect(response.body[0].amount).toBe(99.99);
    });

    it('should not allow access without authentication', async () => {
      await request(app.getHttpServer()).get('/expenses').expect(401);
    });
  });

  describe('GET /expenses/:id', () => {
    it('should return a specific expense when authenticated', async () => {
      const response = await request(app.getHttpServer())
        .get(`/expenses/${expenseId}`)
        .set('Authorization', `Bearer ${jwtToken}`)
        .expect(200);

      expect(response.body).toBeDefined();
      expect(response.body.title).toBe('Test Expense');
      expect(response.body.amount).toBe(99.99);
    });

    it('should not allow access without authentication', async () => {
      await request(app.getHttpServer())
        .get(`/expenses/${expenseId}`)
        .expect(401);
    });
  });

  describe('POST /expenses', () => {
    it('should create an expense when authenticated', async () => {
      // Get initial count of expenses
      const initialExpenses = await expensesService.findAll();
      const initialCount = initialExpenses.length;

      const createExpenseDto = {
        title: 'New Expense',
        amount: 150.5,
        date: new Date().toISOString(),
      };

      const response = await request(app.getHttpServer())
        .post('/expenses')
        .set('Authorization', `Bearer ${jwtToken}`)
        .send(createExpenseDto)
        .expect(201);

      expect(response.body).toBeDefined();
      expect(response.body.title).toBe('New Expense');
      expect(response.body.amount).toBe(150.5);

      // Verify the expense was created in the database
      const allExpenses = await expensesService.findAll();
      expect(allExpenses.length).toBe(initialCount + 1); // Should be one more than before
    });

    it('should not allow creation without authentication', async () => {
      const createExpenseDto = {
        title: 'New Expense',
        amount: 150.5,
        date: new Date().toISOString(),
      };

      await request(app.getHttpServer())
        .post('/expenses')
        .send(createExpenseDto)
        .expect(401);
    });
  });

  describe('DELETE /expenses/:id', () => {
    it('should delete an expense when authenticated', async () => {
      // Get initial count of expenses for this specific user
      const initialExpenses = await expensesService.findAll();
      const targetExpense = initialExpenses.find((exp) => exp.id === expenseId);

      await request(app.getHttpServer())
        .delete(`/expenses/${expenseId}`)
        .set('Authorization', `Bearer ${jwtToken}`)
        .expect(200);

      // Verify the specific expense was deleted
      const remainingExpenses = await expensesService.findAll();
      expect(
        remainingExpenses.find((exp) => exp.id === expenseId)
      ).toBeUndefined();
    });

    it('should not allow deletion without authentication', async () => {
      await request(app.getHttpServer())
        .delete(`/expenses/${expenseId}`)
        .expect(401);
    });
  });
});
