const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  username: { type: String, required: true, unique: true, trim: true },
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  passwordHash: { type: String, required: true },
  avatar: { type: String, default: '⚔️' },
  level: { type: Number, default: 1 },
  xp: { type: Number, default: 0 },
  coins: { type: Number, default: 100 },
  totalSteps: { type: Number, default: 0 },
  totalDistanceKm: { type: Number, default: 0 },
  totalTerritoryKm2: { type: Number, default: 0 },
  streakDays: { type: Number, default: 1 },
  lastActiveDate: { type: Date, default: Date.now },
  playerColor: { type: String, default: '#3B82F6' }, // hex accent color for territory fill
  privacySettings: {
    liveLocation: { type: String, enum: ['off', 'friends', 'everyone'], default: 'friends' },
    activityPublic: { type: Boolean, default: true },
    showOnLeaderboard: { type: Boolean, default: true }
  },
  role: { type: String, enum: ['player', 'admin'], default: 'player' },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.models.User || mongoose.model('User', UserSchema);
