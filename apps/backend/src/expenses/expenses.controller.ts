import {
  Controller,
  Get,
  Post,
  Body,
  Delete,
  Param,
  UseGuards,
  Logger,
  HttpException,
  HttpStatus,
  Res,
} from '@nestjs/common';
import { ExpensesService } from './expenses.service';
import { CreateExpenseDto } from './dto/create-expense.dto';
import { Expense } from './entities/expense.entity';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import * as fs from 'fs';
import * as path from 'path';
import { Response } from 'express';

// Helper function to create directories if they don't exist
const ensureDirectoryExists = (directory: string) => {
  if (!fs.existsSync(directory)) {
    fs.mkdirSync(directory, { recursive: true });
  }
};

@Controller('expenses')
@UseGuards(JwtAuthGuard)
export class ExpensesController {
  private readonly logger = new Logger(ExpensesController.name);

  constructor(private readonly expensesService: ExpensesService) {}

  @Post()
  async create(@Body() createExpenseDto: any): Promise<Expense> {
    try {
      // Log what fields were received
      const receivedFields = Object.keys(createExpenseDto);
      this.logger.log(
        `Received expense with fields: ${receivedFields.join(', ')}`
      );

      // Create the expense data object
      const expenseData: CreateExpenseDto = {
        title: createExpenseDto.title,
        amount: parseFloat(String(createExpenseDto.amount)),
        date: createExpenseDto.date,
        category: createExpenseDto.category,
      };

      // Check specifically for the image
      if (createExpenseDto.receiptImage) {
        try {
          // Extract base64 data (remove any data URL prefix if present)
          let base64Data = createExpenseDto.receiptImage;
          if (base64Data.includes('base64,')) {
            base64Data = base64Data.split('base64,')[1];
          }

          this.logger.log(
            `Receipt image received, base64 data length: ${base64Data.length}`
          );

          // Create a buffer from base64 data
          const imageBuffer = Buffer.from(base64Data, 'base64');

          // Generate a unique filename
          const uploadDir = path.join(process.cwd(), 'uploads');
          ensureDirectoryExists(uploadDir);

          const filename = `receipt-${Date.now()}-${Math.round(Math.random() * 1e9)}.jpg`;
          const filepath = path.join(uploadDir, filename);

          // Write the file
          fs.writeFileSync(filepath, imageBuffer);
          this.logger.log(`Image saved to ${filepath}`);

          // Store the path in the expense data
          expenseData.receiptImage = `/uploads/${filename}`;
        } catch (error: any) {
          this.logger.error(`Error processing image: ${error.message}`);
        }
      } else {
        this.logger.log('No receipt image received in payload');
      }

      // Create and return the expense
      return this.expensesService.create(expenseData);
    } catch (error: any) {
      this.logger.error(`Error creating expense: ${error.message}`);
      throw new HttpException(
        `Failed to create expense: ${error.message}`,
        HttpStatus.BAD_REQUEST
      );
    }
  }

  @Get()
  findAll(): Promise<Expense[]> {
    return this.expensesService.findAll();
  }

  // Updated route path to match the new URL structure
  @Get('uploads/:filename')
  getImage(@Param('filename') filename: string, @Res() res: Response) {
    console.log(`Fetching image: ${filename}`);
    const filePath = path.join(process.cwd(), 'uploads', filename);

    if (!fs.existsSync(filePath)) {
      throw new HttpException('Image not found', HttpStatus.NOT_FOUND);
    }

    return res.sendFile(filePath);
  }

  @Get(':id')
  async findOne(@Param('id') id: string): Promise<Expense | null> {
    return this.expensesService.findOne(id);
  }

  @Delete(':id')
  remove(@Param('id') id: string): Promise<void> {
    return this.expensesService.remove(id);
  }
}
