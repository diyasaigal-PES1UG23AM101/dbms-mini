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

-- ============================================
-- TRIGGERS
-- ============================================

DELIMITER //

-- Trigger 1: Update slot status when booking is confirmed
CREATE TRIGGER after_booking_insert
AFTER INSERT ON Booking
FOR EACH ROW
BEGIN
    IF NEW.Booking_Status IN ('Confirmed', 'Pending') THEN
        UPDATE Slot 
        SET Status = 'Booked'
        WHERE Slot_ID = NEW.Slot_ID;
    END IF;
END //

-- Trigger 2: Handle booking cancellation
CREATE TRIGGER after_booking_cancel
AFTER UPDATE ON Booking
FOR EACH ROW
BEGIN
    IF NEW.Booking_Status = 'Cancelled' AND OLD.Booking_Status != 'Cancelled' THEN
        UPDATE Slot 
        SET Status = 'Available'
        WHERE Slot_ID = NEW.Slot_ID;
    END IF;
END //

-- Trigger 3: Validate court capacity on insert
CREATE TRIGGER before_court_insert_check
BEFORE INSERT ON Court
FOR EACH ROW
BEGIN
    IF NEW.Capacity < 1 OR NEW.Capacity > 50 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Court capacity must be between 1 and 50.';
    END IF;
END //

-- Trigger 4: Calculate booking amount based on court rate
CREATE TRIGGER before_booking_insert_amount
BEFORE INSERT ON Booking
FOR EACH ROW
BEGIN
    DECLARE v_hourly_rate DECIMAL(8,2);
    DECLARE v_duration DECIMAL(5,2);
    
    SELECT Hourly_Rate INTO v_hourly_rate 
    FROM Court WHERE Court_ID = NEW.Court_ID;
    
    SELECT TIMESTAMPDIFF(MINUTE, Start_Time, End_Time) / 60.0 
    INTO v_duration
    FROM Slot WHERE Slot_ID = NEW.Slot_ID;
    
    SET NEW.Total_Amount = v_hourly_rate * v_duration;
END //

-- Trigger 5: Record usage history on booking completion
CREATE TRIGGER after_booking_complete
AFTER UPDATE ON Booking
FOR EACH ROW
BEGIN
    DECLARE v_duration INT;
    DECLARE v_usage_date DATE;
    
    IF NEW.Booking_Status = 'Completed' AND OLD.Booking_Status != 'Completed' THEN
        SELECT TIMESTAMPDIFF(MINUTE, Start_Time, End_Time), Slot_Date
        INTO v_duration, v_usage_date
        FROM Slot WHERE Slot_ID = NEW.Slot_ID;
        
        INSERT INTO Usage_History (SSRN, Court_ID, Slot_ID, Usage_Date, Duration_Minutes)
        VALUES (NEW.SSRN, NEW.Court_ID, NEW.Slot_ID, v_usage_date, v_duration);
        
        UPDATE Slot SET Status = 'Available' WHERE Slot_ID = NEW.Slot_ID;
    END IF;
END //

DELIMITER ;

-- ============================================
-- STORED PROCEDURES
-- ============================================

DELIMITER //

-- Procedure 1: Create new booking with validation
CREATE PROCEDURE CreateNewBooking (
    IN p_SSRN VARCHAR(20),
    IN p_Court_ID INT,
    IN p_Slot_ID INT,
    OUT p_Booking_ID INT,
    OUT p_Message VARCHAR(255)
)
proc_label: BEGIN
    DECLARE v_Court_Status VARCHAR(50);
    DECLARE v_Slot_Status VARCHAR(50);
    DECLARE v_Student_Status VARCHAR(50);
    DECLARE v_Slot_Court_ID INT;
    DECLARE v_Slot_Date DATE;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_Message = 'Error: Transaction failed.';
    END;

    -- Validate student
    SELECT Status INTO v_Student_Status FROM Student WHERE SSRN = p_SSRN;
    IF v_Student_Status IS NULL THEN
        SET p_Message = 'Error: Student not found.';
        LEAVE proc_label;
    ELSEIF v_Student_Status != 'Active' THEN
        SET p_Message = 'Error: Student account is not active.';
        LEAVE proc_label;
    END IF;

    -- Validate court
    SELECT Availability_Status INTO v_Court_Status FROM Court WHERE Court_ID = p_Court_ID;
    IF v_Court_Status != 'Active' THEN
        SET p_Message = CONCAT('Error: Court is ', v_Court_Status);
        LEAVE proc_label;
    END IF;

    -- Validate slot belongs to court
    SELECT Court_ID, Slot_Date INTO v_Slot_Court_ID, v_Slot_Date 
    FROM Slot WHERE Slot_ID = p_Slot_ID;
    
    IF v_Slot_Court_ID != p_Court_ID THEN
        SET p_Message = 'Error: Slot does not belong to this court.';
        LEAVE proc_label;
    END IF;

    -- Check if slot is in the future
    IF v_Slot_Date < CURDATE() THEN
        SET p_Message = 'Error: Cannot book past slots.';
        LEAVE proc_label;
    END IF;

    -- Check slot availability
    SELECT Status INTO v_Slot_Status FROM Slot WHERE Slot_ID = p_Slot_ID;
    IF v_Slot_Status != 'Available' THEN
        SET p_Message = CONCAT('Error: Slot is ', v_Slot_Status);
        LEAVE proc_label;
    END IF;

    -- Create booking
    START TRANSACTION;
    INSERT INTO Booking (SSRN, Court_ID, Slot_ID, Booking_Status)
    VALUES (p_SSRN, p_Court_ID, p_Slot_ID, 'Confirmed');
    
    SET p_Booking_ID = LAST_INSERT_ID();
    COMMIT;
    SET p_Message = CONCAT('Success: Booking created with ID ', p_Booking_ID);
END //

-- Procedure 2: Cancel booking
CREATE PROCEDURE CancelBooking (
    IN p_Booking_ID INT,
    IN p_SSRN VARCHAR(20),
    OUT p_Message VARCHAR(255)
)

BEGIN
    DECLARE v_Current_Status VARCHAR(50);
    DECLARE v_Booking_SSRN VARCHAR(20);
    DECLARE v_Slot_Date DATE;
    
    SELECT Booking_Status, SSRN INTO v_Current_Status, v_Booking_SSRN
    FROM Booking WHERE Booking_ID = p_Booking_ID;
    
    IF v_Current_Status IS NULL THEN
        SET p_Message = 'Error: Booking not found.';
    ELSEIF v_Booking_SSRN != p_SSRN THEN
        SET p_Message = 'Error: Not authorized to cancel this booking.';
    ELSEIF v_Current_Status IN ('Cancelled', 'Completed') THEN
        SET p_Message = 'Error: Booking already cancelled or completed.';
    ELSE
        -- Check if cancellation is within allowed timeframe (24 hours before)
        SELECT S.Slot_Date INTO v_Slot_Date
        FROM Booking B
        JOIN Slot S ON B.Slot_ID = S.Slot_ID
        WHERE B.Booking_ID = p_Booking_ID;
        
        IF DATEDIFF(v_Slot_Date, CURDATE()) < 1 THEN
            SET p_Message = 'Error: Cannot cancel within 24 hours of booking time.';
        ELSE
            UPDATE Booking 
            SET Booking_Status = 'Cancelled',
                Cancellation_Date = NOW()
            WHERE Booking_ID = p_Booking_ID;
            SET p_Message = 'Success: Booking cancelled.';
        END IF;
    END IF;
END //



-- ============================================
-- FUNCTIONS
-- ============================================

DELIMITER //

CREATE FUNCTION GetStudentBookingCount (
    p_SSRN VARCHAR(20),
    p_Year INT,
    p_Month INT
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE booking_count INT;
    SELECT COUNT(*)
    INTO booking_count
    FROM Booking B
    JOIN Slot S ON B.Slot_ID = S.Slot_ID
    WHERE B.SSRN = p_SSRN
      AND YEAR(S.Slot_Date) = p_Year
      AND MONTH(S.Slot_Date) = p_Month
      AND B.Booking_Status IN ('Confirmed', 'Completed');
    RETURN booking_count;
END //

CREATE FUNCTION GetCourtUtilizationRate (
    p_Court_ID INT,
    p_Start_Date DATE,
    p_End_Date DATE
)
RETURNS DECIMAL(5,2)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE total_slots INT;
    DECLARE booked_slots INT;
    DECLARE utilization DECIMAL(5,2);
    
    SELECT COUNT(*) INTO total_slots
    FROM Slot
    WHERE Court_ID = p_Court_ID
      AND Slot_Date BETWEEN p_Start_Date AND p_End_Date;
    
    SELECT COUNT(*) INTO booked_slots
    FROM Slot
    WHERE Court_ID = p_Court_ID
      AND Slot_Date BETWEEN p_Start_Date AND p_End_Date
      AND Status = 'Booked';
    
    IF total_slots = 0 THEN
        RETURN 0;
    END IF;
    
    SET utilization = (booked_slots / total_slots) * 100;
    RETURN utilization;
END //

CREATE FUNCTION GetStaffCourtCount (
    p_Staff_ID INT
)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE court_count INT;
    SELECT COUNT(Court_ID)
    INTO court_count
    FROM Court
    WHERE Staff_ID = p_Staff_ID
      AND Availability_Status = 'Active';
    RETURN court_count;
END //

DELIMITER ;

-- ============================================
-- VIEWS
-- ============================================

-- View 1: Booking details with student and court info
CREATE OR REPLACE VIEW vw_Booking_Details AS
SELECT 
    B.Booking_ID,
    B.SSRN,
    CONCAT(S.First_Name, ' ', S.Last_Name) AS Student_Name,
    S.Department,
    S.Year,
    C.Court_ID,
    SP.Sport_Name,
    C.Location,
    SL.Slot_Date,
    SL.Start_Time,
    SL.End_Time,
    B.Booking_Status,
    B.Total_Amount,
    B.Payment_Status,
    B.Booking_Date
FROM Booking B
JOIN Student S ON B.SSRN = S.SSRN
JOIN Court C ON B.Court_ID = C.Court_ID
JOIN Sport SP ON C.Sport_ID = SP.Sport_ID
JOIN Slot SL ON B.Slot_ID = SL.Slot_ID;

-- View 2: Court availability summary
CREATE OR REPLACE VIEW vw_Court_Availability AS
SELECT 
    C.Court_ID,
    SP.Sport_Name,
    C.Location,
    C.Capacity,
    C.Availability_Status,
    COUNT(CASE WHEN SL.Status = 'Available' THEN 1 END) AS Available_Slots,
    COUNT(CASE WHEN SL.Status = 'Booked' THEN 1 END) AS Booked_Slots
FROM Court C
JOIN Sport SP ON C.Sport_ID = SP.Sport_ID
LEFT JOIN Slot SL ON C.Court_ID = SL.Court_ID AND SL.Slot_Date >= CURDATE()
GROUP BY C.Court_ID, SP.Sport_Name, C.Location, C.Capacity, C.Availability_Status;

-- View 3: Student booking history
CREATE OR REPLACE VIEW vw_Student_Booking_History AS
SELECT 
    S.SSRN,
    CONCAT(S.First_Name, ' ', S.Last_Name) AS Student_Name,
    COUNT(CASE WHEN B.Booking_Status = 'Completed' THEN 1 END) AS Total_Bookings,
    COUNT(CASE WHEN B.Booking_Status = 'Cancelled' THEN 1 END) AS Cancelled_Bookings,
    SUM(CASE WHEN B.Payment_Status = 'Paid' THEN B.Total_Amount ELSE 0 END) AS Total_Spent
FROM Student S
LEFT JOIN Booking B ON S.SSRN = B.SSRN
GROUP BY S.SSRN, S.First_Name, S.Last_Name;
