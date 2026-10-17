require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const connectDB = require('./config/db');
const { initFirebase } = require('./config/firebase');

const app = express();

// Initialize Firebase Admin SDK
initFirebase();

// Connect to MongoDB
connectDB();

// Global Middlewares
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logger for local demo debugging
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    console.log(`[${req.method}] ${req.originalUrl} - ${res.statusCode} (${duration}ms)`);
  });
  next();
});

// ─── Health-Check Endpoint ──────────────────────────────────────────────────
app.get('/health', (req, res) => {
  const dbStatus = mongoose.connection.readyState === 1 ? 'connected' : 'disconnected';
  res.json({
    status: 'ok',
    service: 'NeighbourHub Backend',
    database: {
      type: 'MongoDB',
      status: dbStatus,
      name: mongoose.connection.name || 'neighbourhub',
    },
    network: {
      port: process.env.PORT || 5000,
      host: process.env.HOST || '0.0.0.0',
    },
    timestamp: new Date().toISOString(),
  });
});

// ─── Routes ─────────────────────────────────────────────────────────────────
app.use('/api/users', require('./routes/users'));
app.use('/api/sync', require('./routes/sync'));

// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: `Route not found: ${req.method} ${req.originalUrl}`,
  });
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('[Global Error]', err);
  res.status(500).json({
    success: false,
    error: 'Internal Server Error',
    message: err.message,
  });
});

// ─── Server Start ───────────────────────────────────────────────────────────
const PORT = parseInt(process.env.PORT, 10) || 5000;
const HOST = process.env.HOST || '0.0.0.0';

const server = app.listen(PORT, HOST, () => {
  console.log(`====================================================`);
  console.log(`🚀 NeighbourHub Backend running at http://${HOST}:${PORT}`);
  console.log(`🏥 Health check: http://127.0.0.1:${PORT}/health`);
  console.log(`📱 Over Wi-Fi: http://<YOUR_LAN_IP>:${PORT}/health`);
  console.log(`====================================================`);
});

module.exports = { app, server };
