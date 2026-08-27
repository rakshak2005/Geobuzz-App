const express = require('express');
const router = express.Router();
const db = require('../config/db');
const { protect } = require('../middleware/auth');
const crypto = require('crypto');
const uuidv4 = () => crypto.randomUUID();

// Helper to format DB row to Rule JSON
const formatRule = (row) => ({
  id: row.id,
  userId: row.user_id,
  name: row.name,
  location: {
    name: row.location_name,
    latitude: row.latitude,
    longitude: row.longitude,
    address: row.address,
  },
  radius: row.radius,
  trigger: {
    type: row.trigger_type,
    nearThresholdMeters: row.near_threshold,
    triggerImmediatelyIfInside: row.trigger_immediately,
  },
  action: {
    type: row.action_type,
    soundProfileMode: row.sound_profile_mode,
    exitSoundProfileMode: row.exit_sound_profile_mode,
    alarmDurationSeconds: row.alarm_duration,
    alarmVibrate: row.alarm_vibrate,
    reminderTitle: row.reminder_title,
    reminderMessage: row.reminder_message,
    isOneTime: row.is_one_time,
  },
  isActive: row.is_active,
  createdAt: row.created_at,
  updatedAt: row.updated_at,
});

// @route   POST /api/rules
// @desc    Create a new rule
// @access  Private
router.post('/', protect, async (req, res) => {
  try {
    const {
      id = uuidv4(),
      name,
      location = {},
      radius = 100,
      trigger = {},
      action = {},
      isActive = true,
    } = req.body;

    const query = `
      INSERT INTO rules (
        id, user_id, name, location_name, latitude, longitude, address,
        radius, trigger_type, near_threshold, trigger_immediately,
        action_type, sound_profile_mode, exit_sound_profile_mode,
        alarm_duration, alarm_vibrate, reminder_title, reminder_message,
        is_one_time, is_active, updated_at
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7,
        $8, $9, $10, $11,
        $12, $13, $14,
        $15, $16, $17, $18,
        $19, $20, NOW()
      )
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        location_name = EXCLUDED.location_name,
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude,
        address = EXCLUDED.address,
        radius = EXCLUDED.radius,
        trigger_type = EXCLUDED.trigger_type,
        near_threshold = EXCLUDED.near_threshold,
        trigger_immediately = EXCLUDED.trigger_immediately,
        action_type = EXCLUDED.action_type,
        sound_profile_mode = EXCLUDED.sound_profile_mode,
        exit_sound_profile_mode = EXCLUDED.exit_sound_profile_mode,
        alarm_duration = EXCLUDED.alarm_duration,
        alarm_vibrate = EXCLUDED.alarm_vibrate,
        reminder_title = EXCLUDED.reminder_title,
        reminder_message = EXCLUDED.reminder_message,
        is_one_time = EXCLUDED.is_one_time,
        is_active = EXCLUDED.is_active,
        updated_at = NOW()
      RETURNING *;
    `;

    const values = [
      id,
      req.user.id,
      name || 'Automation Rule',
      location.name || 'Pinned Location',
      location.latitude || 0.0,
      location.longitude || 0.0,
      location.address || '',
      radius,
      trigger.type || 'ENTER',
      trigger.nearThresholdMeters || null,
      trigger.triggerImmediatelyIfInside || false,
      action.type || 'ALARM',
      action.soundProfileMode || null,
      action.exitSoundProfileMode || null,
      action.alarmDurationSeconds || 15,
      action.alarmVibrate !== false,
      action.reminderTitle || null,
      action.reminderMessage || null,
      action.isOneTime || false,
      isActive !== false,
    ];

    const result = await db.query(query, values);

    res.status(201).json({
      success: true,
      data: formatRule(result.rows[0]),
    });
  } catch (error) {
    console.error('Error creating rule in Postgres:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating rule',
      error: error.message,
    });
  }
});

// @route   GET /api/rules
// @desc    Get all rules for logged-in user
// @access  Private
router.get('/', protect, async (req, res) => {
  try {
    const result = await db.query(
      'SELECT * FROM rules WHERE user_id = $1 ORDER BY created_at DESC',
      [req.user.id]
    );

    res.json({
      success: true,
      count: result.rows.length,
      data: result.rows.map(formatRule),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching rules',
      error: error.message,
    });
  }
});

// @route   GET /api/rules/:id
// @desc    Get single rule
// @access  Private
router.get('/:id', protect, async (req, res) => {
  try {
    const result = await db.query(
      'SELECT * FROM rules WHERE id = $1 AND user_id = $2',
      [req.params.id, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Rule not found',
      });
    }

    res.json({
      success: true,
      data: formatRule(result.rows[0]),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching rule',
      error: error.message,
    });
  }
});

// @route   PUT /api/rules/:id
// @desc    Update rule
// @access  Private
router.put('/:id', protect, async (req, res) => {
  try {
    const {
      name,
      location = {},
      radius,
      trigger = {},
      action = {},
      isActive,
    } = req.body;

    const query = `
      UPDATE rules SET
        name = COALESCE($1, name),
        location_name = COALESCE($2, location_name),
        latitude = COALESCE($3, latitude),
        longitude = COALESCE($4, longitude),
        address = COALESCE($5, address),
        radius = COALESCE($6, radius),
        trigger_type = COALESCE($7, trigger_type),
        near_threshold = COALESCE($8, near_threshold),
        trigger_immediately = COALESCE($9, trigger_immediately),
        action_type = COALESCE($10, action_type),
        sound_profile_mode = COALESCE($11, sound_profile_mode),
        exit_sound_profile_mode = COALESCE($12, exit_sound_profile_mode),
        alarm_duration = COALESCE($13, alarm_duration),
        alarm_vibrate = COALESCE($14, alarm_vibrate),
        reminder_title = COALESCE($15, reminder_title),
        reminder_message = COALESCE($16, reminder_message),
        is_one_time = COALESCE($17, is_one_time),
        is_active = COALESCE($18, is_active),
        updated_at = NOW()
      WHERE id = $19 AND user_id = $20
      RETURNING *;
    `;

    const values = [
      name,
      location.name,
      location.latitude,
      location.longitude,
      location.address,
      radius,
      trigger.type,
      trigger.nearThresholdMeters,
      trigger.triggerImmediatelyIfInside,
      action.type,
      action.soundProfileMode,
      action.exitSoundProfileMode,
      action.alarmDurationSeconds,
      action.alarmVibrate,
      action.reminderTitle,
      action.reminderMessage,
      action.isOneTime,
      isActive,
      req.params.id,
      req.user.id,
    ];

    const result = await db.query(query, values);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Rule not found or not authorized',
      });
    }

    res.json({
      success: true,
      data: formatRule(result.rows[0]),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating rule',
      error: error.message,
    });
  }
});

// @route   DELETE /api/rules/:id
// @desc    Delete rule
// @access  Private
router.delete('/:id', protect, async (req, res) => {
  try {
    const result = await db.query(
      'DELETE FROM rules WHERE id = $1 AND user_id = $2 RETURNING id',
      [req.params.id, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Rule not found',
      });
    }

    res.json({
      success: true,
      message: 'Rule deleted successfully',
      data: {},
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error deleting rule',
      error: error.message,
    });
  }
});

// @route   PATCH /api/rules/:id/toggle
// @desc    Toggle rule active state
// @access  Private
router.patch('/:id/toggle', protect, async (req, res) => {
  try {
    const result = await db.query(
      'UPDATE rules SET is_active = NOT is_active, updated_at = NOW() WHERE id = $1 AND user_id = $2 RETURNING *',
      [req.params.id, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Rule not found',
      });
    }

    res.json({
      success: true,
      data: formatRule(result.rows[0]),
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error toggling rule status',
      error: error.message,
    });
  }
});

module.exports = router;