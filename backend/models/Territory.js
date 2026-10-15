const mongoose = require('mongoose');
const { Schema } = mongoose;

const TerritorySchema = new Schema({
  ownerId: { type: Schema.Types.Mixed, required: true, index: true },
  ownerName: { type: String, required: true },
  geometry: {
    type: {
      type: String,
      enum: ['Polygon', 'MultiPolygon'],
      default: 'Polygon',
      required: true
    },
    coordinates: {
      type: Schema.Types.Mixed, // GeoJSON coordinate array
      required: true
    }
  },
  areaKm2: { type: Number, required: true },
  perimeterKm: { type: Number, default: 0 },
  color: { type: String, default: '#3B82F6' },
  status: { type: String, enum: ['active', 'captured', 'archived'], default: 'active' },
  sourceActivityId: { type: Schema.Types.Mixed },
  version: { type: Number, default: 1 },
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
});

TerritorySchema.index({ geometry: '2dsphere' });

module.exports = mongoose.models.Territory || mongoose.model('Territory', TerritorySchema);
