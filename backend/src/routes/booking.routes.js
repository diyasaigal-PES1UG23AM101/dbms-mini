const express = require('express');
const { authenticateToken } = require('../middleware/auth');
const router = express.Router();

// Create a new booking
router.post('/', authenticateToken, async (req, res) => {
  const pool = req.app.locals.pool;
  const { courtId, slotId } = req.body;
  const ssrn = req.user.ssrn;

  try {
    if (!courtId || !slotId) {
      return res.status(400).json({ error: 'Court ID and Slot ID are required' });
    }

    // Check if slot is available
    const [slots] = await pool.execute(
      'SELECT Status, Court_ID FROM Slot WHERE Slot_ID = ?',
      [slotId]
    );

    if (slots.length === 0) {
      return res.status(404).json({ error: 'Slot not found' });
    }

    if (slots[0].Status !== 'Available') {
      return res.status(400).json({ error: 'Slot is not available' });
    }

    if (slots[0].Court_ID !== parseInt(courtId)) {
      return res.status(400).json({ error: 'Slot does not belong to the specified court' });
    }

    // Get court hourly rate
    const [courts] = await pool.execute(
      'SELECT Hourly_Rate, Availability_Status FROM Court WHERE Court_ID = ?',
      [courtId]
    );

    if (courts.length === 0) {
      return res.status(404).json({ error: 'Court not found' });
    }

    if (courts[0].Availability_Status !== 'Active') {
      return res.status(400).json({ error: 'Court is not available for booking' });
    }

    // Calculate duration and amount
    const [slotDetails] = await pool.execute(
      'SELECT Start_Time, End_Time FROM Slot WHERE Slot_ID = ?',
      [slotId]
    );

    if (slotDetails.length === 0) {
      return res.status(404).json({ error: 'Slot details not found' });
    }

    // Parse time strings (HH:MM:SS format)
    const startTimeStr = slotDetails[0].Start_Time;
    const endTimeStr = slotDetails[0].End_Time;
    
    // Convert time string to seconds
    const parseTimeToSeconds = (timeStr) => {
      const parts = timeStr.split(':');
      return parseInt(parts[0]) * 3600 + parseInt(parts[1]) * 60 + parseInt(parts[2] || 0);
    };
    
    const startSeconds = parseTimeToSeconds(startTimeStr);
    const endSeconds = parseTimeToSeconds(endTimeStr);
    const durationHours = (endSeconds - startSeconds) / 3600;
    const totalAmount = durationHours * parseFloat(courts[0].Hourly_Rate || 0);

    // Start transaction
    const connection = await pool.getConnection();
    await connection.beginTransaction();

    try {
      // Create booking
      const [result] = await connection.execute(
        `INSERT INTO Booking (SSRN, Court_ID, Slot_ID, Booking_Status, Total_Amount, Payment_Status)
         VALUES (?, ?, ?, 'Pending', ?, 'Unpaid')`,
        [ssrn, courtId, slotId, totalAmount]
      );

      const bookingId = result.insertId;

      // Update slot status
      await connection.execute(
        'UPDATE Slot SET Status = "Booked" WHERE Slot_ID = ?',
        [slotId]
      );

      await connection.commit();
      connection.release();

      // Fetch created booking
      const [bookings] = await pool.execute(
        `SELECT 
          b.Booking_ID,
          b.Booking_Date,
          b.Booking_Status,
          b.Total_Amount,
          b.Payment_Status,
          c.Court_Name,
          c.Location,
          s.Slot_Date,
          s.Start_Time,
          s.End_Time
        FROM Booking b
        JOIN Court c ON b.Court_ID = c.Court_ID
        JOIN Slot s ON b.Slot_ID = s.Slot_ID
        WHERE b.Booking_ID = ?`,
        [bookingId]
      );

      res.status(201).json({
        message: 'Booking created successfully',
        booking: bookings[0]
      });
    } catch (error) {
      await connection.rollback();
      connection.release();
      throw error;
    }
  } catch (error) {
    console.error('Booking creation error:', error);
    res.status(500).json({ error: 'Failed to create booking', message: error.message });
  }
});

// Get user's bookings
router.get('/', authenticateToken, async (req, res) => {
  const pool = req.app.locals.pool;
  const ssrn = req.user.ssrn;

  try {
    const { status } = req.query;
    let query = `
      SELECT 
        b.Booking_ID,
        b.Booking_Date,
        b.Booking_Status,
        b.Total_Amount,
        b.Payment_Status,
        b.Cancellation_Date,
        b.Notes,
        c.Court_ID,
        c.Court_Name,
        c.Location,
        c.Hourly_Rate,
        s.Sport_Name,
        sl.Slot_ID,
        sl.Slot_Date,
        sl.Start_Time,
        sl.End_Time
      FROM Booking b
      JOIN Court c ON b.Court_ID = c.Court_ID
      JOIN Sport s ON c.Sport_ID = s.Sport_ID
      JOIN Slot sl ON b.Slot_ID = sl.Slot_ID
      WHERE b.SSRN = ?
    `;

    const params = [ssrn];

    if (status) {
      query += ' AND b.Booking_Status = ?';
      params.push(status);
    }

    query += ' ORDER BY b.Booking_Date DESC';

    const [bookings] = await pool.execute(query, params);
    res.json(bookings);
  } catch (error) {
    console.error('Error fetching bookings:', error);
    res.status(500).json({ error: 'Failed to fetch bookings', message: error.message });
  }
});

// Get booking by ID
router.get('/:id', authenticateToken, async (req, res) => {
  const pool = req.app.locals.pool;
  const ssrn = req.user.ssrn;

  try {
    const [bookings] = await pool.execute(
      `SELECT 
        b.Booking_ID,
        b.Booking_Date,
        b.Booking_Status,
        b.Total_Amount,
        b.Payment_Status,
        b.Cancellation_Date,
        b.Notes,
        c.Court_ID,
        c.Court_Name,
        c.Location,
        c.Hourly_Rate,
        s.Sport_Name,
        sl.Slot_ID,
        sl.Slot_Date,
        sl.Start_Time,
        sl.End_Time
      FROM Booking b
      JOIN Court c ON b.Court_ID = c.Court_ID
      JOIN Sport s ON c.Sport_ID = s.Sport_ID
      JOIN Slot sl ON b.Slot_ID = sl.Slot_ID
      WHERE b.Booking_ID = ? AND b.SSRN = ?`,
      [req.params.id, ssrn]
    );

    if (bookings.length === 0) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    res.json(bookings[0]);
  } catch (error) {
    console.error('Error fetching booking:', error);
    res.status(500).json({ error: 'Failed to fetch booking', message: error.message });
  }
});

// Cancel booking
router.put('/:id/cancel', authenticateToken, async (req, res) => {
  const pool = req.app.locals.pool;
  const ssrn = req.user.ssrn;

  try {
    // Get booking
    const [bookings] = await pool.execute(
      'SELECT Booking_Status, Slot_ID FROM Booking WHERE Booking_ID = ? AND SSRN = ?',
      [req.params.id, ssrn]
    );

    if (bookings.length === 0) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    const booking = bookings[0];

    if (booking.Booking_Status === 'Cancelled') {
      return res.status(400).json({ error: 'Booking is already cancelled' });
    }

    if (booking.Booking_Status === 'Completed') {
      return res.status(400).json({ error: 'Cannot cancel completed booking' });
    }

    // Start transaction
    const connection = await pool.getConnection();
    await connection.beginTransaction();

    try {
      // Update booking
      await connection.execute(
        `UPDATE Booking 
         SET Booking_Status = 'Cancelled', 
             Cancellation_Date = CURRENT_TIMESTAMP
         WHERE Booking_ID = ?`,
        [req.params.id]
      );

      // Free up slot
      await connection.execute(
        'UPDATE Slot SET Status = "Available" WHERE Slot_ID = ?',
        [booking.Slot_ID]
      );

      await connection.commit();
      connection.release();

      res.json({ message: 'Booking cancelled successfully' });
    } catch (error) {
      await connection.rollback();
      connection.release();
      throw error;
    }
  } catch (error) {
    console.error('Cancellation error:', error);
    res.status(500).json({ error: 'Failed to cancel booking', message: error.message });
  }
});

// Mark payment as paid
router.put('/:id/pay', authenticateToken, async (req, res) => {
  const pool = req.app.locals.pool;
  const ssrn = req.user.ssrn;
  const { paymentMethod, transactionId } = req.body;

  try {
    // Get booking details
    const [bookings] = await pool.execute(
      'SELECT Booking_ID, Total_Amount, Payment_Status, Booking_Status FROM Booking WHERE Booking_ID = ? AND SSRN = ?',
      [req.params.id, ssrn]
    );

    if (bookings.length === 0) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    const booking = bookings[0];

    if (booking.Payment_Status === 'Paid') {
      return res.status(400).json({ error: 'Booking is already paid' });
    }

    if (booking.Booking_Status === 'Cancelled') {
      return res.status(400).json({ error: 'Cannot pay for cancelled booking' });
    }

    // Start transaction
    const connection = await pool.getConnection();
    await connection.beginTransaction();

    try {
      // Update payment status
      await connection.execute(
        'UPDATE Booking SET Payment_Status = "Paid" WHERE Booking_ID = ?',
        [req.params.id]
      );

      // Create payment record
      const [paymentResult] = await connection.execute(
        `INSERT INTO Payment (Booking_ID, Amount, Payment_Method, Transaction_ID)
         VALUES (?, ?, ?, ?)`,
        [req.params.id, booking.Total_Amount, paymentMethod || 'Cash', transactionId || null]
      );

      await connection.commit();
      connection.release();

      res.json({ message: 'Payment recorded successfully' });
    } catch (error) {
      await connection.rollback();
      connection.release();
      throw error;
    }
  } catch (error) {
    console.error('Payment error:', error);
    res.status(500).json({ error: 'Failed to process payment', message: error.message });
  }
});

// Confirm booking (update status to Confirmed)
router.put('/:id/confirm', authenticateToken, async (req, res) => {
  const pool = req.app.locals.pool;
  const ssrn = req.user.ssrn;

  try {
    // Get booking details
    const [bookings] = await pool.execute(
      'SELECT Booking_Status, Payment_Status FROM Booking WHERE Booking_ID = ? AND SSRN = ?',
      [req.params.id, ssrn]
    );

    if (bookings.length === 0) {
      return res.status(404).json({ error: 'Booking not found' });
    }

    const booking = bookings[0];

    if (booking.Booking_Status === 'Confirmed') {
      return res.status(400).json({ error: 'Booking is already confirmed' });
    }

    if (booking.Booking_Status === 'Cancelled') {
      return res.status(400).json({ error: 'Cannot confirm cancelled booking' });
    }

    if (booking.Booking_Status === 'Completed') {
      return res.status(400).json({ error: 'Cannot confirm completed booking' });
    }

    // Optionally check if payment is required before confirmation
    // For now, we'll allow confirmation regardless of payment status
    // You can uncomment below if you want to require payment first
    // if (booking.Payment_Status !== 'Paid') {
    //   return res.status(400).json({ error: 'Payment must be completed before confirming booking' });
    // }

    await pool.execute(
      'UPDATE Booking SET Booking_Status = "Confirmed" WHERE Booking_ID = ?',
      [req.params.id]
    );

    res.json({ message: 'Booking confirmed successfully' });
  } catch (error) {
    console.error('Confirmation error:', error);
    res.status(500).json({ error: 'Failed to confirm booking', message: error.message });
  }
});

module.exports = router;

