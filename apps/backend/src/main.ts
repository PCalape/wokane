import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { Logger, ValidationPipe } from '@nestjs/common';
import * as dotenv from 'dotenv';

// Load environment variables from .env file
dotenv.config();

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule);

  // Enable CORS for the frontend application with more permissive configuration
  // For development, we'll allow all origins for easier testing
  if (process.env.NODE_ENV === 'production') {
    app.enableCors({
      origin: [
        'http://localhost:8080', // Flutter web server
        'http://localhost:3000', // Frontend development server
        'http://127.0.0.1:8080', // Alternative Flutter web server address
        // Add your production domains here
      ],
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
      credentials: true,
      allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
    });
  } else {
    // For development, allow any origin
    app.enableCors({
      origin: true, // Allow any origin in development
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
      credentials: true,
      allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
    });
  }

  // Set up global validation pipes
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true, // Strip properties not in the DTO
      transform: true, // Transform payload objects to DTO instances
      forbidNonWhitelisted: true, // Throw errors when non-whitelisted properties are present
      transformOptions: {
        enableImplicitConversion: true, // Automatically transform primitive types
      },
    })
  );

  const port = process.env.PORT || 3000;
  const nodeEnv = process.env.NODE_ENV || 'development';

  await app.listen(port, '0.0.0.0'); // Listen on all network interfaces
  logger.log(
    `Application is running in ${nodeEnv} mode on: http://localhost:${port}`
  );
}
bootstrap();
