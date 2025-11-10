# College Sports Court Booking System

A comprehensive web-based system for managing sports court bookings at a college. Built with React frontend and Node.js/Express backend with MySQL database.

## Features

### Student Features
- **User Registration & Authentication**: Secure registration and login for students
- **View Available Courts**: Browse all available sports courts with filters
- **Book Court Slots**: Select a court, date, and available time slot to make a booking
- **View My Bookings**: See all your bookings with status and details
- **Cancel Bookings**: Cancel pending or confirmed bookings
- **Real-time Availability**: Check slot availability for specific dates

### Admin Features
- **Admin Authentication**: Separate login system for staff members
- **Dashboard**: Comprehensive statistics overview with metrics
- **Court Management**: Create, update, and delete courts
- **Booking Management**: View all bookings with filters 
- **Sports Management**: Manage sports in the system 
- **Staff Management**: Manage staff members 
- **Slot Management**: Manage time slots for courts 

## Database Schema

### Strong Entities
- **Sport**: Sports available in the system
- **Staff**: Staff members managing courts
- **Court**: Sports courts available for booking
- **Student**: Registered students who can book courts
- **Slot**: Time slots for court bookings
- **Booking**: Student court bookings
  
### Weak Entities
- **Equipment**: Depends on Court and Sport
  
## Tech Stack

### Backend
- Node.js
- Express.js
- MySQL2
- JWT (JSON Web Tokens) for authentication
- Bcrypt for password hashing

### Frontend
- React 18
- React Router DOM
- Vite for build tooling

## Prerequisites

- Node.js (v14 or higher)
- MySQL (v8.0 or higher)
- npm or yarn

## Setup Instructions

### 1. Database Setup

1. Create MySQL database:
```sql
CREATE DATABASE sports_court_booking;
```

2. Import the schema:
```bash
mysql -u root -p sports_court_booking < database/schema.sql
```

Or execute the SQL file directly in MySQL:
```sql
USE sports_court_booking;
SOURCE database/schema.sql;
```

### 2. Backend Setup

1. Navigate to backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create `.env` file (copy from `.env.example`):
```env
PORT=5000
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=sports_court_booking
JWT_SECRET=your_secret_key_here_change_in_production
```

4. Start the backend server:
```bash
npm run dev
```

The backend will run on `http://localhost:5000`

### 3. Frontend Setup

1. Navigate to frontend directory:
```bash
cd frontend
```

2. Install dependencies:
```bash
npm install
```

3. Start the development server:
```bash
npm run dev
```

The frontend will run on `http://localhost:5173`

## Sample Data

You can insert sample data using the SQL file `database/sample_data.sql`:

```bash
mysql -u root -p sports_court_booking < database/sample_data.sql
```

Or manually insert test data:

```sql
-- Insert Sports
INSERT INTO Sport (Sport_Name, Description) VALUES
('Basketball', 'Basketball court with standard dimensions'),
('Tennis', 'Tennis court with net and boundary lines'),
('Volleyball', 'Volleyball court with net'),
('Badminton', 'Indoor badminton court'),
('Football', 'Football field with goal posts');

-- Insert Staff
INSERT INTO Staff (Staff_Name, Email, Role) VALUES
('John Manager', 'john@college.edu', 'Manager'),
('Jane Coach', 'jane@college.edu', 'Coach'),
('Bob Admin', 'bob@college.edu', 'Admin');

-- Insert Courts
INSERT INTO Court (Sport_ID, Court_Name, Sport_Type, Staff_ID, Location, Capacity, Hourly_Rate, Availability_Status) VALUES
(1, 'Basketball Court 1', 'Basketball', 1, 'Sports Complex A', 20, 500.00, 'Active'),
(2, 'Tennis Court 1', 'Tennis', 2, 'Sports Complex A', 4, 800.00, 'Active'),
(3, 'Volleyball Court 1', 'Volleyball', 2, 'Sports Complex B', 12, 600.00, 'Active');

-- Insert Slots (example for today and next 7 days)
-- Note: Adjust dates as needed
INSERT INTO Slot (Court_ID, Slot_Date, Start_Time, End_Time, Status) VALUES
(1, CURDATE(), '09:00:00', '10:00:00', 'Available'),
(1, CURDATE(), '10:00:00', '11:00:00', 'Available'),
(1, CURDATE(), '11:00:00', '12:00:00', 'Available'),
(2, CURDATE(), '09:00:00', '10:00:00', 'Available'),
(2, CURDATE(), '10:00:00', '11:00:00', 'Available');
```


## Project Structure

```
new/
├── backend/
│   ├── src/
│   │   ├── middleware/
│   │   │   └── auth.js
│   │   └── routes/
│   │       ├── auth.routes.js
│   │       ├── court.routes.js
│   │       ├── booking.routes.js
│   │       ├── sport.routes.js
│   │       └── admin.routes.js
│   ├── server.js
│   ├── package.json
│   └── .env.example
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── Login.jsx
│   │   │   ├── Register.jsx
│   │   │   ├── Dashboard.jsx
│   │   │   ├── CourtBooking.jsx
│   │   │   ├── MyBookings.jsx
│   │   │   └── Navbar.jsx
│   │   ├── contexts/
│   │   │   └── AuthContext.jsx
│   │   ├── services/
│   │   │   └── api.js
│   │   ├── App.jsx
│   │   └── main.jsx
│   ├── package.json
│   └── vite.config.js
├── database/
│   └── schema.sql
└── README.md
```

## Usage

1. **Register/Login**: Create an account or login with existing credentials
2. **Browse Courts**: View available courts on the dashboard
3. **Book a Court**: 
   - Click "Book Now" on a court or use the "Book Court" menu
   - Select court, date, and available time slot
   - Confirm booking
4. **View Bookings**: Check your bookings and their status
5. **Cancel Booking**: Cancel bookings that haven't been completed

## Security Features

- Password hashing using bcrypt
- JWT token-based authentication
- Protected API routes
- SQL injection prevention using parameterized queries
- CORS configuration



## Author

College Sports Court Booking System - DBMS Mini Project

