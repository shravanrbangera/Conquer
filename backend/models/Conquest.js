const mongoose = require('mongoose');
const { Schema } = mongoose;

const ConquestSchema = new Schema({
  userId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  activityId: { type: Schema.Types.ObjectId, ref: 'Activity', required: true },
  originalAreaKm2: { type: Number, required: true },
  capturedAreaKm2: { type: Number, default: 0 },
  netAreaKm2: { type: Number, required: true },
  territoryIds: [{ type: Schema.Types.ObjectId, ref: 'Territory' }],
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.models.Conquest || mongoose.model('Conquest', ConquestSchema);
