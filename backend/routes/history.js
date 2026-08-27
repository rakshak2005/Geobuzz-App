const express = require('express');
const router = express.Router();
const History = require('../models/History');
const { protect } = require('../middleware/auth');

// @route   POST /api/history
// @desc    Create history entry
// @access  Private
router.post('/', protect, async (req, res) => {
  try {
    const history = await History.create({
      ...req.body,
      userId: req.user.id
    });

    res.status(201).json({
      success: true,
      data: history
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error creating history entry',
      error: error.message
    });
  }
});

// @route   GET /api/history
// @desc    Get all history for logged-in user
// @access  Private
router.get('/', protect, async (req, res) => {
  try {
    const { limit = 50, offset = 0, ruleId, status } = req.query;

    const query = { userId: req.user.id };
    if (ruleId) query.ruleId = ruleId;
    if (status) query.status = status;

    const history = await History.find(query)
      .sort({ timestamp: -1 })
      .skip(parseInt(offset))
      .limit(parseInt(limit));

    const total = await History.countDocuments(query);

    res.json({
      success: true,
      count: history.length,
      total,
      data: history
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching history',
      error: error.message
    });
  }
});

// @route   DELETE /api/history
// @desc    Clear all history for user
// @access  Private
router.delete('/', protect, async (req, res) => {
  try {
    await History.deleteMany({ userId: req.user.id });

    res.json({
      success: true,
      message: 'All history cleared'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error clearing history',
      error: error.message
    });
  }
});

module.exports = router;