const mongoose = require('mongoose');
const { Schema } = mongoose;

const FriendshipSchema = new Schema({
  requesterId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  receiverId: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  status: { type: String, enum: ['pending', 'accepted', 'rejected'], default: 'pending' },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.models.Friendship || mongoose.model('Friendship', FriendshipSchema);
