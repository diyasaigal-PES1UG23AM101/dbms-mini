-- Sports Court Booking System Database Schema
-- Create database first: CREATE DATABASE sports_court_booking;

USE sports_court_booking;

-- Sport table (Strong Entity)
CREATE TABLE IF NOT EXISTS Sport (
    Sport_ID INT PRIMARY KEY AUTO_INCREMENT,
    Sport_Name VARCHAR(50) NOT NULL UNIQUE,
    Description TEXT
);

-- Staff table (Strong Entity)
CREATE TABLE IF NOT EXISTS Staff (
    Staff_ID INT PRIMARY KEY AUTO_INCREMENT,
    Staff_Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE,
    Role ENUM('Manager', 'Coach', 'Admin', 'Supervisor') DEFAULT 'Admin',
    Reports_To INT,
    FOREIGN KEY (Reports_To) REFERENCES Staff(Staff_ID)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- Staff_Phone table (Weak Entity - depends on Staff)
CREATE TABLE IF NOT EXISTS Staff_Phone (
    Staff_ID INT NOT NULL,
    Phone_Number VARCHAR(15) NOT NULL,
    Phone_Type ENUM('Mobile', 'Office', 'Emergency') DEFAULT 'Mobile',
    PRIMARY KEY (Staff_ID, Phone_Number),
    FOREIGN KEY (Staff_ID) REFERENCES Staff(Staff_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Court table (Strong Entity)
CREATE TABLE IF NOT EXISTS Court (
    Court_ID INT PRIMARY KEY AUTO_INCREMENT,
    Sport_ID INT NOT NULL,
    Court_Name VARCHAR(100) NOT NULL,
    Sport_Type VARCHAR(100),
    Staff_ID INT NOT NULL,
    Location VARCHAR(100) NOT NULL,
    Capacity INT NOT NULL CHECK (Capacity > 0),
    Hourly_Rate DECIMAL(8,2) DEFAULT 0.00,
    Availability_Status ENUM('Active', 'Inactive', 'Under Maintenance') DEFAULT 'Active',
    FOREIGN KEY (Sport_ID) REFERENCES Sport(Sport_ID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (Staff_ID) REFERENCES Staff(Staff_ID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Student table (Strong Entity)
CREATE TABLE IF NOT EXISTS Student (
    SSRN VARCHAR(20) PRIMARY KEY,
    First_Name VARCHAR(50) NOT NULL,
    Last_Name VARCHAR(50) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Password_Hash VARCHAR(255) NOT NULL,
    Department VARCHAR(50) NOT NULL,
    Year INT NOT NULL CHECK (Year BETWEEN 1 AND 4),
    Date_of_Birth DATE NOT NULL,
    Registration_Date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Status ENUM('Active', 'Suspended', 'Graduated') DEFAULT 'Active'
);

-- Student_Phone table (Weak Entity - depends on Student)
CREATE TABLE IF NOT EXISTS Student_Phone (
    SSRN VARCHAR(20) NOT NULL,
    Phone_Number VARCHAR(15) NOT NULL,
    Phone_Type ENUM('Mobile', 'Home', 'Emergency') DEFAULT 'Mobile',
    PRIMARY KEY (SSRN, Phone_Number),
    FOREIGN KEY (SSRN) REFERENCES Student(SSRN)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Slot table (Strong Entity)
CREATE TABLE IF NOT EXISTS Slot (
    Slot_ID INT PRIMARY KEY AUTO_INCREMENT,
    Court_ID INT NOT NULL,
    Slot_Date DATE NOT NULL,
    Start_Time TIME NOT NULL,
    End_Time TIME NOT NULL,
    Status ENUM('Available', 'Booked', 'Blocked') DEFAULT 'Available',
    CHECK (End_Time > Start_Time),
    UNIQUE (Court_ID, Slot_Date, Start_Time, End_Time),
    FOREIGN KEY (Court_ID) REFERENCES Court(Court_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Booking table (Strong Entity)
CREATE TABLE IF NOT EXISTS Booking (
    Booking_ID INT PRIMARY KEY AUTO_INCREMENT,
    SSRN VARCHAR(20) NOT NULL,
    Court_ID INT NOT NULL,
    Slot_ID INT NOT NULL,
    Booking_Date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Booking_Status ENUM('Pending', 'Confirmed', 'Cancelled', 'Completed', 'No-Show') DEFAULT 'Pending',
    Total_Amount DECIMAL(8,2) DEFAULT 0.00,
    Payment_Status ENUM('Unpaid', 'Paid', 'Refunded') DEFAULT 'Unpaid',
    Cancellation_Date TIMESTAMP NULL,
    Notes TEXT,
    FOREIGN KEY (SSRN) REFERENCES Student(SSRN)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (Court_ID) REFERENCES Court(Court_ID)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (Slot_ID) REFERENCES Slot(Slot_ID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Equipment table (Weak Entity - depends on Court and Sport)
CREATE TABLE IF NOT EXISTS Equipment (
    Equipment_ID INT AUTO_INCREMENT,
    Court_ID INT NOT NULL,
    Sport_ID INT NOT NULL,
    Equipment_Name VARCHAR(100) NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity >= 0),
    Condition_Status ENUM('Good', 'Fair', 'Poor', 'Damaged') DEFAULT 'Good',
    Last_Maintenance_Date DATE,
    PRIMARY KEY (Equipment_ID, Court_ID, Sport_ID),
    FOREIGN KEY (Court_ID) REFERENCES Court(Court_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (Sport_ID) REFERENCES Sport(Sport_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Usage_History table (Strong Entity)
CREATE TABLE IF NOT EXISTS Usage_History (
    Usage_ID INT PRIMARY KEY AUTO_INCREMENT,
    SSRN VARCHAR(20) NOT NULL,
    Court_ID INT NOT NULL,
    Slot_ID INT NOT NULL,
    Usage_Date DATE NOT NULL,
    Duration_Minutes INT,
    FOREIGN KEY (SSRN) REFERENCES Student(SSRN)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (Court_ID) REFERENCES Court(Court_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Payment table (Strong Entity)
CREATE TABLE IF NOT EXISTS Payment (
    Payment_ID INT PRIMARY KEY AUTO_INCREMENT,
    Booking_ID INT NOT NULL,
    Amount DECIMAL(8,2) NOT NULL,
    Payment_Method ENUM('Cash', 'Card', 'UPI', 'Wallet') NOT NULL,
    Payment_Date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Transaction_ID VARCHAR(100) UNIQUE,
    FOREIGN KEY (Booking_ID) REFERENCES Booking(Booking_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- Indexes for better performance
CREATE INDEX idx_booking_ssrn ON Booking(SSRN);
CREATE INDEX idx_booking_court ON Booking(Court_ID);
CREATE INDEX idx_booking_status ON Booking(Booking_Status);
CREATE INDEX idx_slot_court_date ON Slot(Court_ID, Slot_Date);
CREATE INDEX idx_court_sport ON Court(Sport_ID);
CREATE INDEX idx_court_status ON Court(Availability_Status);

