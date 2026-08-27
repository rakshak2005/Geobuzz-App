const mongoose = require('mongoose');

const historySchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  ruleId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Rule',
    required: true
  },
  ruleName: {
    type: String,
    required: true
  },
  triggerType: {
    type: String,
    required: true,
    enum: ['ENTER', 'EXIT', 'NEAR']
  },
  actionType: {
    type: String,
    required: true,
    enum: ['ALARM', 'SOUND_PROFILE', 'WIFI', 'BLUETOOTH', 'REMINDER']
  },
  location: {
    name: String,
    latitude: Number,
    longitude: Number
  },
  timestamp: {
    type: Date,
    default: Date.now
  },
  status: {
    type: String,
    enum: ['SUCCESS', 'FAILED', 'PARTIAL'],
    default: 'SUCCESS'
  },
  errorMessage: {
    type: String
  },
  metadata: {
    deviceInfo: String,
    accuracy: Number,
    batteryLevel: Number
  }
}, { timestamps: true });

// Index for efficient querying and sorting
historySchema.index({ userId: 1, timestamp: -1 });
historySchema.index({ ruleId: 1, timestamp: -1 });

module.exports = mongoose.model('History', historySchema);