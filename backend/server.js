/**
 * CONQUER — Main Node.js + Express API Server Entry
 */

const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const apiRoutes = require('./routes/api');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Health Check
app.get('/health', (req, res) => {
  res.json({
    status: 'online',
    app: 'CONQUER Engine API',
    version: '1.0.0',
    timestamp: new Date()
  });
});

// API Routes
app.use('/api', apiRoutes);

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('Unhandled Server Error:', err);
  res.status(500).json({ error: 'Internal Server Error', message: err.message });
});

app.listen(PORT, () => {
  console.log(`=======================================================`);
  console.log(`⚔️ CONQUER API Server running on port ${PORT}`);
  console.log(`⚔️ Real-world Territory Engine Ready`);
  console.log(`=======================================================`);
});

module.exports = app;
