const mongoose = require('mongoose');
const { Schema } = mongoose;

const TerritoryEventSchema = new Schema({
  territoryId: { type: Schema.Types.ObjectId, ref: 'Territory' },
  attackerId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  defenderId: { type: Schema.Types.ObjectId, ref: 'User' },
  type: { type: String, enum: ['created', 'captured', 'trimmed', 'lost'], required: true },
  areaKm2: { type: Number, required: true },
  activityId: { type: Schema.Types.ObjectId, ref: 'Activity' },
  timestamp: { type: Date, default: Date.now }
});

module.exports = mongoose.models.TerritoryEvent || mongoose.model('TerritoryEvent', TerritoryEventSchema);
