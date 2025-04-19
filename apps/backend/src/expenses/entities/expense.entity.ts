import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

@Schema()
export class Expense extends Document {
  @Prop({ required: true })
  title!: string;

  @Prop({ required: true })
  amount!: number;

  @Prop({ required: true })
  date!: Date;

  @Prop()
  category?: string;

  @Prop()
  receiptImage?: string;
}

export const ExpenseSchema = SchemaFactory.createForClass(Expense);
