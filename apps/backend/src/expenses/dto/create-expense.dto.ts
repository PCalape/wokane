import { IsNumber, IsOptional, IsString, IsDateString } from 'class-validator';
import { Type, Transform } from 'class-transformer';

export class CreateExpenseDto {
  @IsString()
  title!: string;

  @IsNumber()
  amount!: number;

  @IsDateString()
  date!: string;

  @IsOptional()
  @IsString()
  category?: string;

  @IsOptional()
  @IsString()
  receiptImage?: string;
}
