const express = require('express');
const router = express.Router();
const Rule = require('../models/Rule');
const { protect } = require('../middleware/auth');

// @route   POST /api/rules
// @desc    Create a new rule
// @access  Private
router.post('/', protect, async (req, res) => {
  try {
    const rule = await Rule.create({
      ...req.body,
      userId: req.user.id
    });

    res.status(201).json({
      success: true,
      data: rule
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error creating rule',
      error: error.message
    });
  }
});

// @route   GET /api/rules
// @desc    Get all rules for logged-in user
// @access  Private
router.get('/', protect, async (req, res) => {
  try {
    const rules = await Rule.find({ userId: req.user.id }).sort({ createdAt: -1 });

    res.json({
      success: true,
      count: rules.length,
      data: rules
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching rules',
      error: error.message
    });
  }
});

// @route   GET /api/rules/:id
// @desc    Get single rule
// @access  Private
router.get('/:id', protect, async (req, res) => {
  try {
    const rule = await Rule.findOne({
      _id: req.params.id,
      userId: req.user.id
    });

    if (!rule) {
      return res.status(404).json({
        success: false,
        message: 'Rule not found'
      });
    }

    res.json({
      success: true,
      data: rule
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching rule',
      error: error.message
    });
  }
});

// @route   PUT /api/rules/:id
// @desc    Update rule
// @access  Private
router.put('/:id', protect, async (req, res) => {
  try {
    let rule = await Rule.findOne({
      _id: req.params.id,
      userId: req.user.id
    });

    if (!rule) {
      return res.status(404).json({
        success: false,
        message: 'Rule not found'
      });
    }

    rule = await Rule.findByIdAndUpdate(
      req.params.id,
      { $set: req.body },
      { new: true, runValidators: true }
    );

    res.json({
      success: true,
      data: rule
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating rule',
      error: error.message
    });
  }
});

// @route   DELETE /api/rules/:id
// @desc    Delete rule
// @access  Private
router.delete('/:id', protect, async (req, res) => {
  try {
    const rule = await Rule.findOne({
      _id: req.params.id,
      userId: req.user.id
    });

    if (!rule) {
      return res.status(404).json({
        success: false,
        message: 'Rule not found'
      });
    }

    await rule.deleteOne();

    res.json({
      success: true,
      message: 'Rule deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error deleting rule',
      error: error.message
    });
  }
});

// @route   PATCH /api/rules/:id/status
// @desc    Toggle rule active status
// @access  Private
router.patch('/:id/status', protect, async (req, res) => {
  try {
    const { isActive } = req.body;

    const rule = await Rule.findOne({
      _id: req.params.id,
      userId: req.user.id
    });

    if (!rule) {
      return res.status(404).json({
        success: false,
        message: 'Rule not found'
      });
    }

    rule.isActive = isActive !== undefined ? isActive : !rule.isActive;
    await rule.save();

    res.json({
      success: true,
      data: rule
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating rule status',
      error: error.message
    });
  }
});

module.exports = router;