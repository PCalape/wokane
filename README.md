# Wokane App

This is an Wokane application built with Flutter as the frontend and NestJS as the backend. The application allows users to register, log in, and manage their expenses efficiently.

## Project Structure

```
expense-tracker-app
├── apps
│   ├── backend
│   │   ├── src
│   │   │   ├── app.module.ts
│   │   │   ├── main.ts
│   │   │   ├── auth
│   │   │   │   ├── auth.controller.ts
│   │   │   │   ├── auth.module.ts
│   │   │   │   └── auth.service.ts
│   │   │   ├── users
│   │   │   │   ├── users.controller.ts
│   │   │   │   ├── users.module.ts
│   │   │   │   └── users.service.ts
│   │   │   └── expenses
│   │   │       ├── expenses.controller.ts
│   │   │       ├── expenses.module.ts
│   │   │       └── expenses.service.ts
│   │   ├── package.json
│   │   ├── tsconfig.json
│   │   └── Dockerfile
│   └── frontend
│       ├── lib
│       │   ├── main.dart
│       │   ├── screens
│       │   │   ├── login_screen.dart
│       │   │   ├── registration_screen.dart
│       │   │   └── expense_tracker_screen.dart
│       │   └── widgets
│       │       ├── custom_button.dart
│       │       └── custom_input_field.dart
│       ├── pubspec.yaml
│       └── Dockerfile
├── docker-compose.yml
└── README.md
```

## Features

- User Registration: Users can create an account to start tracking their expenses.
- User Login: Users can log in to access their expense data.
- Expense Management: Users can add, view, and delete their expenses.

## Technologies Used

- **Frontend**: Flutter
- **Backend**: NestJS
- **Database**: (Specify your choice, e.g., MongoDB, PostgreSQL)
- **Containerization**: Docker

## Getting Started

### Prerequisites

- Docker
- Flutter SDK
- Node.js and npm

### Setup Instructions

1. Clone the repository:

   ```
   git clone <repository-url>
   cd expense-tracker-app
   ```

2. Navigate to the backend directory and install dependencies:

   ```
   cd apps/backend
   npm install
   ```

3. Navigate to the frontend directory and install dependencies:

   ```
   cd apps/frontend
   flutter pub get
   ```

4. Build and run the application using Docker:

   ```
   docker-compose up --build
   ```

5. Access the application:
   - Frontend: `http://localhost:3000` (or the port specified in your Docker configuration)
   - Backend: `http://localhost:4000` (or the port specified in your Docker configuration)

## Usage

- Register a new account to start tracking expenses.
- Log in with your credentials to access your dashboard.
- Add, view, and delete expenses as needed.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
