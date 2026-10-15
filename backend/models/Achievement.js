const mongoose = require('mongoose');
const { Schema } = mongoose;

const AchievementSchema = new Schema({
  code: { type: String, required: true, unique: true },
  name: { type: String, required: true },
  description: { type: String, required: true },
  icon: { type: String, default: '🏆' },
  conditionType: { 
    type: String, 
    enum: ['TOTAL_STEPS', 'TOTAL_DISTANCE', 'TERRITORY_OWNED', 'CONQUEST_COUNT', 'STREAK_DAYS', 'EXPLORATION_KM'],
    required: true
  },
  threshold: { type: Number, required: true },
  rewardXP: { type: Number, default: 100 },
  rewardCoins: { type: Number, default: 50 },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.models.Achievement || mongoose.model('Achievement', AchievementSchema);
