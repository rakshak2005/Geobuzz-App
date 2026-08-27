const { Pool } = require('pg');
const dns = require('dns').promises;
require('dotenv').config();

try {
  dns.setServers(['8.8.8.8', '1.1.1.1', '8.8.4.4']);
} catch (_) {}

const DATABASE_URL = process.env.DATABASE_URL || 
  'postgresql://neondb_owner:npg_Zkn8brI6Xafw@ep-solitary-violet-az648tl2-pooler.c-3.ap-southeast-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require';

let pool = null;

const createPool = async () => {
  if (pool) return pool;

  const url = new URL(DATABASE_URL);
  const hostname = url.hostname;
  let resolvedHost = hostname;

  try {
    const addresses = await dns.resolve4(hostname);
    if (addresses && addresses.length > 0) {
      resolvedHost = addresses[0];
    }
  } catch (err) {
    console.warn(`DNS resolve failed for ${hostname}, using raw hostname:`, err.message);
  }

  pool = new Pool({
    host: resolvedHost,
    port: parseInt(url.port) || 5432,
    user: url.username,
    password: decodeURIComponent(url.password),
    database: url.pathname.replace(/^\//, ''),
    ssl: {
      servername: hostname,
      rejectUnauthorized: false,
    },
    max: 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 10000,
  });

  pool.on('error', (err) => {
    console.error('Unexpected idle client error in Neon PostgreSQL pool:', err);
  });

  return pool;
};

// Initialize PostgreSQL Tables
const initializeDatabase = async () => {
  const p = await createPool();
  const client = await p.connect();
  try {
    console.log('Connected to Neon PostgreSQL Database successfully.');

    // 1. Users Table
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `);

    // 2. Rules Table
    await client.query(`
      CREATE TABLE IF NOT EXISTS rules (
        id VARCHAR(255) PRIMARY KEY,
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        name VARCHAR(255) NOT NULL,
        location_name VARCHAR(255) NOT NULL,
        latitude DOUBLE PRECISION NOT NULL,
        longitude DOUBLE PRECISION NOT NULL,
        address TEXT,
        radius DOUBLE PRECISION NOT NULL,
        trigger_type VARCHAR(50) NOT NULL,
        near_threshold DOUBLE PRECISION,
        trigger_immediately BOOLEAN DEFAULT FALSE,
        action_type VARCHAR(50) NOT NULL,
        sound_profile_mode VARCHAR(50),
        exit_sound_profile_mode VARCHAR(50),
        alarm_duration INTEGER DEFAULT 15,
        alarm_vibrate BOOLEAN DEFAULT TRUE,
        reminder_title TEXT,
        reminder_message TEXT,
        is_one_time BOOLEAN DEFAULT FALSE,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `);

    // 3. History Table
    await client.query(`
      CREATE TABLE IF NOT EXISTS history (
        id VARCHAR(255) PRIMARY KEY,
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        rule_id VARCHAR(255),
        rule_name VARCHAR(255) NOT NULL,
        location_name VARCHAR(255) NOT NULL,
        trigger_type VARCHAR(50) NOT NULL,
        action_type VARCHAR(50) NOT NULL,
        status VARCHAR(50) NOT NULL,
        message TEXT,
        timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `);

    console.log('Neon PostgreSQL database tables (users, rules, history) created and verified.');
  } catch (err) {
    console.error('Error initializing PostgreSQL tables:', err.message);
    throw err;
  } finally {
    client.release();
  }
};

module.exports = {
  createPool,
  query: async (text, params) => {
    const p = await createPool();
    return p.query(text, params);
  },
  initializeDatabase,
};
