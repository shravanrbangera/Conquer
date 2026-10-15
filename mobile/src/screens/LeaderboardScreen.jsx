import React, { useState } from 'react';
import { Trophy, Globe, MapPin, Users, Crown } from 'lucide-react';
import ThreeTrophy from '../components/3d/ThreeTrophy';

export default function LeaderboardScreen({ users = [] }) {
  const [tab, setTab] = useState('global');

  const sortedUsers = [...users].sort((a, b) => (b.totalTerritoryKm2 || 0) - (a.totalTerritoryKm2 || 0));

  const top1 = sortedUsers[0];
  const top2 = sortedUsers[1];
  const top3 = sortedUsers[2];

  return (
    <div className="flex flex-col h-full bg-navy-950 text-white p-4 pb-24 overflow-y-auto ambient-bg">
      {/* Header */}
      <div className="flex items-center justify-between mb-3">
        <div>
          <h1 className="font-heading font-black text-2xl text-white tracking-tight flex items-center gap-2">
            <Trophy className="w-6 h-6 text-amber-400 fill-current animate-bounce" /> LEADERBOARD
          </h1>
          <p className="text-[11px] text-cyan-400 font-semibold">Ranked by total controlled real-world territory</p>
        </div>
      </div>

      {/* Tabs */}
      <div className="grid grid-cols-3 gap-1 bg-gray-950/80 p-1.5 rounded-2xl border border-gray-800 mb-5">
        <button
          onClick={() => setTab('global')}
          className={`py-2 px-3 rounded-xl font-black text-xs flex items-center justify-center gap-1.5 transition ${
            tab === 'global' ? 'bg-cyan-500 text-navy-950 shadow-lg glow-cyan-lg' : 'text-gray-400 hover:text-white'
          }`}
        >
          <Globe className="w-3.5 h-3.5" /> Global
        </button>
        <button
          onClick={() => setTab('nearby')}
          className={`py-2 px-3 rounded-xl font-black text-xs flex items-center justify-center gap-1.5 transition ${
            tab === 'nearby' ? 'bg-cyan-500 text-navy-950 shadow-lg glow-cyan-lg' : 'text-gray-400 hover:text-white'
          }`}
        >
          <MapPin className="w-3.5 h-3.5" /> Nearby
        </button>
        <button
          onClick={() => setTab('friends')}
          className={`py-2 px-3 rounded-xl font-black text-xs flex items-center justify-center gap-1.5 transition ${
            tab === 'friends' ? 'bg-cyan-500 text-navy-950 shadow-lg glow-cyan-lg' : 'text-gray-400 hover:text-white'
          }`}
        >
          <Users className="w-3.5 h-3.5" /> Friends
        </button>
      </div>

      {/* Top 3 Podium Winners Showcase with WebGL 3D Trophy */}
      <div className="grid grid-cols-3 gap-2 mb-5 items-end">
        {/* 2nd Place */}
        {top2 && (
          <div className="cyber-glass rounded-2xl p-3 text-center border border-gray-700 flex flex-col items-center">
            <div className="text-xl mb-1">🥈</div>
            <div
              className="w-11 h-11 rounded-2xl flex items-center justify-center text-lg font-bold shadow-md border-2 border-slate-300 mb-1"
              style={{ backgroundColor: top2.playerColor || '#FF0055' }}
            >
              {top2.avatar || '🛡️'}
            </div>
            <div className="font-heading font-black text-xs text-white truncate max-w-full">{top2.username}</div>
            <div className="text-[10px] text-cyan-400 font-bold mt-0.5">{top2.totalTerritoryKm2.toFixed(1)} km²</div>
          </div>
        )}

        {/* 1st Place Champion with 3D Trophy */}
        {top1 && (
          <div className="cyber-glass rounded-3xl p-3 text-center border-2 border-amber-400/80 flex flex-col items-center glow-gold-lg relative -top-2">
            <div className="absolute -top-3 left-1/2 -translate-x-1/2 bg-amber-400 text-navy-950 font-black text-[9px] px-2 py-0.5 rounded-full uppercase tracking-wider flex items-center gap-1">
              <Crown className="w-3 h-3 fill-current" /> Champion
            </div>
            
            {/* WebGL 3D Gold Trophy */}
            <div className="w-24 h-24 -my-2 flex items-center justify-center">
              <ThreeTrophy width={110} height={110} />
            </div>

            <div className="font-heading font-black text-xs text-amber-300 truncate max-w-full">{top1.username}</div>
            <div className="text-xs font-black text-amber-400 mt-0.5">{top1.totalTerritoryKm2.toFixed(2)} km²</div>
          </div>
        )}

        {/* 3rd Place */}
        {top3 && (
          <div className="cyber-glass rounded-2xl p-3 text-center border border-gray-700 flex flex-col items-center">
            <div className="text-xl mb-1">🥉</div>
            <div
              className="w-11 h-11 rounded-2xl flex items-center justify-center text-lg font-bold shadow-md border-2 border-amber-700 mb-1"
              style={{ backgroundColor: top3.playerColor || '#00FF9D' }}
            >
              {top3.avatar || '🏃‍♀️'}
            </div>
            <div className="font-heading font-black text-xs text-white truncate max-w-full">{top3.username}</div>
            <div className="text-[10px] text-cyan-400 font-bold mt-0.5">{top3.totalTerritoryKm2.toFixed(1)} km²</div>
          </div>
        )}
      </div>

      {/* Remaining Ranks List */}
      <div className="flex flex-col gap-2">
        {sortedUsers.map((user, idx) => {
          if (idx < 3) return null;

          return (
            <div
              key={user.id || idx}
              className="cyber-glass rounded-2xl p-3 flex items-center justify-between border border-gray-800"
            >
              <div className="flex items-center gap-3">
                <div className="w-6 font-heading font-black text-xs text-gray-400 text-center">
                  #{idx + 1}
                </div>

                <div
                  className="w-9 h-9 rounded-xl flex items-center justify-center text-base font-bold shadow-md border border-white/20"
                  style={{ backgroundColor: user.playerColor || '#3B82F6' }}
                >
                  {user.avatar || '⚔️'}
                </div>

                <div>
                  <div className="font-heading font-bold text-xs text-white flex items-center gap-2">
                    {user.username}
                    <span className="text-[9px] px-1.5 py-0.5 rounded-full bg-blue-950 text-cyan-400 font-extrabold border border-blue-800">
                      Lvl {user.level || 1}
                    </span>
                  </div>
                  <div className="text-[10px] text-gray-400">
                    🚶 {(user.totalSteps || 0).toLocaleString()} steps
                  </div>
                </div>
              </div>

              <div className="text-right">
                <div className="font-heading font-black text-sm text-cyan-400">
                  {(user.totalTerritoryKm2 || 0).toFixed(2)} <span className="text-[9px] text-gray-400 font-normal">km²</span>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
