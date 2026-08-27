const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { protect } = require('../middleware/auth');
const { v4: uuidv4 } = require('uuid');

// @route   POST /api/history
// @desc    Create history entry
// @access  Private
router.post('/', protect, async (req, res) => {
  try {
    const {
      id = uuidv4(),
      ruleId,
      ruleName,
      locationName,
      triggerType,
      actionType,
      status = 'SUCCESS',
      message,
    } = req.body;

    const query = `
      INSERT INTO history (
        id, user_id, rule_id, rule_name, location_name,
        trigger_type, action_type, status, message, timestamp
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW())
      RETURNING *;
    `;

    const values = [
      id,
      req.user.id,
      ruleId || null,
      ruleName || 'Unnamed Rule',
      locationName || 'Unknown Location',
      triggerType || 'ENTER',
      actionType || 'ALARM',
      status,
      message || '',
    ];

    const result = await db.query(query, values);

    res.status(201).json({
      success: true,
      data: result.rows[0],
    });
  } catch (error) {
    console.error('Error recording history in Postgres:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating history entry',
      error: error.message,
    });
  }
});

// @route   GET /api/history
// @desc    Get all history for logged-in user
// @access  Private
router.get('/', protect, async (req, res) => {
  try {
    const { limit = 50, offset = 0 } = req.query;

    const result = await db.query(
      'SELECT * FROM history WHERE user_id = $1 ORDER BY timestamp DESC LIMIT $2 OFFSET $3',
      [req.user.id, parseInt(limit), parseInt(offset)]
    );

    const countResult = await db.query(
      'SELECT COUNT(*) FROM history WHERE user_id = $1',
      [req.user.id]
    );

    res.json({
      success: true,
      count: result.rows.length,
      total: parseInt(countResult.rows[0].count),
      data: result.rows,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching history',
      error: error.message,
    });
  }
});

// @route   DELETE /api/history
// @desc    Clear all history for logged-in user
// @access  Private
router.delete('/', protect, async (req, res) => {
  try {
    await db.query('DELETE FROM history WHERE user_id = $1', [req.user.id]);

    res.json({
      success: true,
      message: 'History cleared successfully',
      data: {},
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error clearing history',
      error: error.message,
    });
  }
});

module.exports = router;