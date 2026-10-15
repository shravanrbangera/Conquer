const mongoose = require('mongoose');
const { Schema } = mongoose;

const RestrictedZoneSchema = new Schema({
  name: { type: String, required: true },
  reason: { type: String, default: 'Restricted area / Trespassing prohibited' },
  geometry: {
    type: { type: String, enum: ['Polygon'], default: 'Polygon' },
    coordinates: [[[Number]]]
  },
  status: { type: String, enum: ['active', 'disabled'], default: 'active' },
  createdBy: { type: Schema.Types.ObjectId, ref: 'User' },
  createdAt: { type: Date, default: Date.now }
});

RestrictedZoneSchema.index({ geometry: '2dsphere' });

module.exports = mongoose.models.RestrictedZone || mongoose.model('RestrictedZone', RestrictedZoneSchema);
