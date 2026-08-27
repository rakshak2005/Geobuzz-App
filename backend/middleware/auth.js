const jwt = require('jsonwebtoken');
const db = require('../config/db');

// Protect routes
exports.protect = async (req, res, next) => {
  try {
    let token;

    // Check for token in Authorization header
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
      token = req.headers.authorization.split(' ')[1];
    }

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Not authorized to access this route'
      });
    }

    // Verify token
    const secret = process.env.JWT_SECRET || 'geobuzz_production_secret_key_2026_super_secure_jwt';
    const decoded = jwt.verify(token, secret);

    // Find user in PostgreSQL
    const { rows } = await db.query('SELECT id, name, email, created_at FROM users WHERE id = $1', [decoded.id]);
    if (rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'User not found'
      });
    }

    req.user = rows[0];
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Not authorized to access this route'
    });
  }
};