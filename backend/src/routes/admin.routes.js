const express = require('express');
const { authenticateToken } = require('../middleware/auth');
const router = express.Router();

// Middleware to check admin role (assuming staff with Admin role)
// In a real system, you'd verify the staff member's role
const checkAdmin = (req, res, next) => {
  // For now, allow if authenticated - in production, check for admin role
  next();
};

// Get all bookings (admin view)
router.get('/bookings', authenticateToken, checkAdmin, async (req, res) => {
  const pool = req.app.locals.pool;
  try {
    const { status } = req.query;
    let query = `
      SELECT 
        b.Booking_ID,
        b.Booking_Date,
        b.Booking_Status,
        b.Total_Amount,
        b.Payment_Status,
        st.SSRN,
        st.First_Name,
        st.Last_Name,
        st.Email,
        c.Court_Name,
        c.Location,
        s.Sport_Name,
        sl.Slot_Date,
        sl.Start_Time,
        sl.End_Time
      FROM Booking b
      JOIN Student st ON b.SSRN = st.SSRN
      JOIN Court c ON b.Court_ID = c.Court_ID
      JOIN Sport s ON c.Sport_ID = s.Sport_ID
      JOIN Slot sl ON b.Slot_ID = sl.Slot_ID
    `;

    const params = [];

    if (status) {
      query += ' WHERE b.Booking_Status = ?';
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

// Get dashboard stats
router.get('/dashboard', authenticateToken, checkAdmin, async (req, res) => {
  const pool = req.app.locals.pool;
  try {
    const [stats] = await pool.execute(`
      SELECT 
        (SELECT COUNT(*) FROM Booking WHERE Booking_Status = 'Confirmed') as confirmed_bookings,
        (SELECT COUNT(*) FROM Booking WHERE Booking_Status = 'Pending') as pending_bookings,
        (SELECT COUNT(*) FROM Booking WHERE Booking_Status = 'Cancelled') as cancelled_bookings,
        (SELECT COUNT(*) FROM Court WHERE Availability_Status = 'Active') as active_courts,
        (SELECT COUNT(*) FROM Student WHERE Status = 'Active') as active_students,
        (SELECT SUM(Total_Amount) FROM Booking WHERE Payment_Status = 'Paid') as total_revenue
    `);

    res.json(stats[0]);
  } catch (error) {
    console.error('Error fetching dashboard stats:', error);
    res.status(500).json({ error: 'Failed to fetch dashboard stats', message: error.message });
  }
});

module.exports = router;

