const mongoose = require('mongoose');

const locationSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Please provide a location name'],
    trim: true,
    maxlength: [100, 'Location name cannot be more than 100 characters']
  },
  latitude: {
    type: Number,
    required: true,
    min: -90,
    max: 90
  },
  longitude: {
    type: Number,
    required: true,
    min: -180,
    max: 180
  },
  address: {
    type: String,
    trim: true
  }
}, { _id: false });

const actionSchema = new mongoose.Schema({
  type: {
    type: String,
    required: true,
    enum: ['ALARM', 'SOUND_PROFILE', 'WIFI', 'BLUETOOTH', 'REMINDER']
  },
  config: {
    // For ALARM
    alarmSound: { type: String },
    volume: { type: Number, min: 0, max: 100 },
    duration: { type: Number }, // in seconds
    vibration: { type: Boolean },

    // For SOUND_PROFILE
    soundMode: {
      type: String,
      enum: ['SILENT', 'VIBRATE', 'NORMAL']
    },
    restoreOnExit: { type: Boolean, default: true },

    // For REMINDER
    reminderTitle: { type: String },
    reminderMessage: { type: String },
    repeatOnEnter: { type: Boolean, default: false },

    // For WIFI (limited on Android 10+)
    wifiAction: {
      type: String,
      enum: ['ON', 'OFF', 'OPEN_SETTINGS']
    },

    // For BLUETOOTH
    bluetoothAction: {
      type: String,
      enum: ['ON', 'OFF', 'OPEN_SETTINGS']
    }
  }
}, { _id: false });

const ruleSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  name: {
    type: String,
    required: [true, 'Please provide a rule name'],
    trim: true,
    maxlength: [100, 'Rule name cannot be more than 100 characters']
  },
  location: {
    type: locationSchema,
    required: true
  },
  radius: {
    type: Number,
    required: true,
    min: [10, 'Radius must be at least 10 meters'],
    max: [5000, 'Radius cannot exceed 5000 meters']
  },
  trigger: {
    type: String,
    required: true,
    enum: ['ENTER', 'EXIT', 'ENTER_EXIT', 'NEAR']
  },
  enterAction: {
    type: actionSchema
  },
  exitAction: {
    type: actionSchema
  },
  nearAction: {
    type: actionSchema
  },
  nearDistance: {
    type: Number,
    min: 10,
    max: 2000
  },
  isActive: {
    type: Boolean,
    default: true
  },
  schedule: {
    enabled: { type: Boolean, default: false },
    startTime: { type: String }, // HH:MM format
    endTime: { type: String },
    daysOfWeek: [{ type: Number, min: 0, max: 6 }] // 0 = Sunday
  },
  lastTriggered: {
    type: Date
  },
  triggerCount: {
    type: Number,
    default: 0
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
}, { timestamps: true });

// Index for efficient querying
ruleSchema.index({ userId: 1, isActive: 1 });

module.exports = mongoose.model('Rule', ruleSchema);