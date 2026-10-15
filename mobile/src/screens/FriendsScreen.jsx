import React, { useState } from 'react';
import { Search, UserPlus, Check, X, Shield, Swords } from 'lucide-react';

export default function FriendsScreen() {
  const [searchQuery, setSearchQuery] = useState('');
  const [friends, setFriends] = useState([
    { id: 'f1', username: 'RAHUL', level: 11, territoryKm2: 14.5, color: '#EF4444', avatar: '🛡️', status: 'online' },
    { id: 'f2', username: 'PRIYA_RUNNER', level: 9, territoryKm2: 8.9, color: '#10B981', avatar: '🏃‍♀️', status: 'offline' },
    { id: 'f3', username: 'AKASH_CONQUEROR', level: 7, territoryKm2: 5.2, color: '#F59E0B', avatar: '🦁', status: 'online' }
  ]);

  const [requests, setRequests] = useState([
    { id: 'r1', username: 'VIKRAM_99', level: 5, territoryKm2: 2.4 }
  ]);

  const handleAccept = (reqId) => {
    const req = requests.find(r => r.id === reqId);
    if (req) {
      setFriends([...friends, { ...req, color: '#8B5CF6', avatar: '⚔️', status: 'online' }]);
      setRequests(requests.filter(r => r.id !== reqId));
    }
  };

  return (
    <div className="flex flex-col h-full bg-navy-950 text-white p-4 pb-24 overflow-y-auto">
      <div className="mb-4">
        <h1 className="font-heading font-black text-2xl text-white tracking-tight flex items-center gap-2">
          <Swords className="w-6 h-6 text-blue-400" /> FRIENDS & RIVALS
        </h1>
        <p className="text-xs text-gray-400">Connect with fellow conquerors and compare empires</p>
      </div>

      {/* Search Input */}
      <div className="relative mb-5">
        <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-3.5" />
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="Search by username..."
          className="w-full pl-10 pr-4 py-3 rounded-2xl bg-gray-900/90 border border-gray-800 text-sm text-white focus:outline-none focus:border-blue-500 transition"
        />
      </div>

      {/* Pending Requests */}
      {requests.length > 0 && (
        <div className="mb-5">
          <h2 className="font-heading font-extrabold text-xs text-amber-400 uppercase tracking-wider mb-2">
            Pending Conquest Requests ({requests.length})
          </h2>
          {requests.map(req => (
            <div key={req.id} className="glass-panel rounded-2xl p-3.5 border border-amber-500/30 flex items-center justify-between">
              <div>
                <div className="font-bold text-sm text-white">{req.username}</div>
                <div className="text-xs text-gray-400">Lvl {req.level} • {req.territoryKm2} km² Owned</div>
              </div>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => handleAccept(req.id)}
                  className="p-2 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white transition"
                >
                  <Check className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Friends List */}
      <h2 className="font-heading font-extrabold text-xs text-gray-400 uppercase tracking-wider mb-3">
        Your Empire Allies ({friends.length})
      </h2>

      <div className="flex flex-col gap-3">
        {friends.map(friend => (
          <div key={friend.id} className="glass-panel rounded-2xl p-4 flex items-center justify-between border border-gray-800">
            <div className="flex items-center gap-3">
              <div
                className="w-12 h-12 rounded-2xl flex items-center justify-center text-xl font-bold shadow-md border border-white/20 relative"
                style={{ backgroundColor: friend.color }}
              >
                {friend.avatar}
                <span className={`absolute -bottom-1 -right-1 w-3.5 h-3.5 rounded-full border-2 border-navy-950 ${
                  friend.status === 'online' ? 'bg-emerald-500' : 'bg-gray-500'
                }`} />
              </div>

              <div>
                <div className="font-heading font-bold text-base text-white">
                  {friend.username}
                </div>
                <div className="text-xs text-gray-400">
                  Level {friend.level} Conqueror
                </div>
              </div>
            </div>

            <div className="text-right">
              <div className="font-heading font-extrabold text-base text-blue-400">
                {friend.territoryKm2.toFixed(2)} km²
              </div>
              <div className="text-[10px] text-gray-400 font-medium">Territory</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
