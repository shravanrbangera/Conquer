const mongoose = require('mongoose');
const { Schema } = mongoose;

const ActivitySchema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  type: { type: String, enum: ['walking', 'running'], default: 'walking' },
  startTime: { type: Date, default: Date.now },
  endTime: { type: Date, default: Date.now },
  durationSeconds: { type: Number, default: 0 },
  distanceKm: { type: Number, default: 0 },
  steps: { type: Number, default: 0 },
  route: {
    type: { type: String, default: 'LineString' },
    coordinates: [[Number]] // GeoJSON [[lng, lat]]
  },
  loopCompleted: { type: Boolean, default: false },
  loopDistanceMeters: { type: Number, default: 0 },
  returnDistanceMeters: { type: Number, default: 0 },
  areaConqueredKm2: { type: Number, default: 0 },
  trustScore: { type: Number, default: 100 },
  validationStatus: { type: String, enum: ['passed', 'suspicious', 'rejected'], default: 'passed' },
  xpEarned: { type: Number, default: 0 },
  coinsEarned: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.models.Activity || mongoose.model('Activity', ActivitySchema);
