const express = require('express');
const cors = require('cors');
require('dotenv').config();

const db = require('./config/db');
const authRoutes = require('./routes/auth');
const ruleRoutes = require('./routes/rules');
const historyRoutes = require('./routes/history');
const userRoutes = require('./routes/users');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Initialize PostgreSQL Database Connection and Schema
db.initializeDatabase().catch((err) => {
  console.error('Database initialization error:', err.message);
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/rules', ruleRoutes);
app.use('/api/history', historyRoutes);
app.use('/api/users', userRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    database: 'Neon PostgreSQL (Connected)',
    timestamp: new Date().toISOString(),
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Internal server error',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined,
  });
});

module.exports = app;