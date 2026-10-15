const mongoose = require('mongoose');
const { Schema } = mongoose;

const NotificationSchema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  type: { type: String, enum: ['attack', 'conquest', 'achievement', 'streak', 'system'], default: 'system' },
  title: { type: String, required: true },
  message: { type: String, required: true },
  relatedUserId: { type: Schema.Types.ObjectId, ref: 'User' },
  relatedTerritoryId: { type: Schema.Types.ObjectId, ref: 'Territory' },
  read: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.models.Notification || mongoose.model('Notification', NotificationSchema);
