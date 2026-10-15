import React from 'react';
import { Shield, Zap, Flame, Coins, Award, Sparkles, Crown } from 'lucide-react';
import ThreeShield from '../components/3d/ThreeShield';

export default function ProfileScreen({ user }) {
  if (!user) return null;

  const achievements = [
    { name: 'First Explorer', desc: 'Conquered 1st territory loop', icon: '🧭' },
    { name: 'Pathfinder', desc: 'Walked over 50 km distance', icon: '🌎' },
    { name: 'Land Master', desc: 'Owned over 10 km² territory', icon: '👑' },
    { name: '7-Day Streak', desc: 'Active for 7 consecutive days', icon: '🔥' }
  ];

  return (
    <div className="flex flex-col h-full bg-navy-950 text-white p-4 pb-24 overflow-y-auto ambient-bg">
      {/* Cyberpunk Conqueror Card */}
      <div className="cyber-glass rounded-3xl p-5 border-2 border-cyan-500/40 mb-5 relative overflow-hidden shadow-2xl glow-cyan-lg">
        <div className="absolute top-0 right-0 w-36 h-36 bg-cyan-500/10 rounded-full blur-3xl pointer-events-none"></div>

        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-3">
            <div
              className="w-16 h-16 rounded-2xl flex items-center justify-center text-3xl shadow-2xl border-2 border-white/30 glow-cyan-lg"
              style={{ backgroundColor: user.playerColor || '#3B82F6' }}
            >
              {user.avatar || '⚔️'}
            </div>

            <div>
              <div className="flex items-center gap-2">
                <h1 className="font-heading font-black text-xl text-white tracking-tight">
                  {user.username}
                </h1>
                <span className="bg-amber-500/20 text-amber-300 font-extrabold text-[10px] px-2 py-0.5 rounded-full border border-amber-500/40 flex items-center gap-1">
                  <Flame className="w-3 h-3 fill-current text-amber-400" /> {user.streakDays || 28}d
                </span>
              </div>
              <div className="text-[11px] text-cyan-400 font-extrabold uppercase tracking-wider flex items-center gap-1 mt-0.5">
                <Crown className="w-3 h-3 text-amber-400" /> Lvl {user.level || 14} • Conqueror
              </div>
            </div>
          </div>

          {/* WebGL 3D Cyber Shield Model Badge */}
          <div className="w-20 h-20 -my-2 flex items-center justify-center shrink-0">
            <ThreeShield width={90} height={90} color={0x00F0FF} />
          </div>
        </div>

        {/* XP Level Gauge */}
        <div className="bg-gray-950/80 rounded-2xl p-3 border border-gray-800 mb-3">
          <div className="flex justify-between text-xs font-black mb-1.5">
            <span className="text-gray-300 flex items-center gap-1">
              <Zap className="w-3.5 h-3.5 text-amber-400 fill-current" /> XP Progress
            </span>
            <span className="text-amber-400">78% ({user.xp || 19600} / 22500 XP)</span>
          </div>
          <div className="w-full h-2.5 bg-gray-900 rounded-full overflow-hidden p-0.5 border border-gray-800">
            <div className="h-full bg-gradient-to-r from-amber-500 via-yellow-400 to-amber-300 rounded-full shadow-lg" style={{ width: '78%' }}></div>
          </div>
        </div>

        {/* Currency Row */}
        <div className="flex items-center justify-around bg-gray-950/90 rounded-2xl p-2.5 border border-gray-800">
          <div className="flex items-center gap-2">
            <Coins className="w-4 h-4 text-yellow-400 fill-current" />
            <span className="font-black text-xs text-white">{user.coins || 1450} Coins</span>
          </div>
          <div className="h-4 w-px bg-gray-800"></div>
          <div className="flex items-center gap-2">
            <Shield className="w-4 h-4 text-cyan-400" />
            <span className="font-black text-xs text-white">37 Conquests</span>
          </div>
        </div>
      </div>

      {/* Career Telemetry Grid */}
      <h2 className="font-heading font-extrabold text-xs text-gray-400 uppercase tracking-widest mb-3 flex items-center gap-1.5">
        <Sparkles className="w-3.5 h-3.5 text-cyan-400" /> Career Telemetry Metrics
      </h2>
      <div className="grid grid-cols-2 gap-3 mb-5">
        <div className="cyber-glass rounded-2xl p-3.5 border border-cyan-500/30">
          <div className="text-[10px] text-gray-400 font-semibold uppercase">Total Controlled Land</div>
          <div className="text-xl font-black text-cyan-400 font-heading my-0.5">
            {(user.totalTerritoryKm2 || 24.82).toFixed(2)} <span className="text-xs font-normal text-gray-400">km²</span>
          </div>
        </div>

        <div className="cyber-glass rounded-2xl p-3.5 border border-emerald-500/30">
          <div className="text-[10px] text-gray-400 font-semibold uppercase">Total Distance</div>
          <div className="text-xl font-black text-emerald-400 font-heading my-0.5">
            {(user.totalDistanceKm || 642.5).toFixed(1)} <span className="text-xs font-normal text-gray-400">km</span>
          </div>
        </div>

        <div className="cyber-glass rounded-2xl p-3.5 border border-purple-500/30">
          <div className="text-[10px] text-gray-400 font-semibold uppercase">Lifetime Steps</div>
          <div className="text-xl font-black text-purple-400 font-heading my-0.5">
            {(user.totalSteps || 1240500).toLocaleString()}
          </div>
        </div>

        <div className="cyber-glass rounded-2xl p-3.5 border border-amber-500/30">
          <div className="text-[10px] text-gray-400 font-semibold uppercase">Daily Streak</div>
          <div className="text-xl font-black text-amber-400 font-heading my-0.5">
            {user.streakDays || 28} <span className="text-xs font-normal text-gray-400">Days</span>
          </div>
        </div>
      </div>

      {/* Unlocked Badges */}
      <h2 className="font-heading font-extrabold text-xs text-gray-400 uppercase tracking-widest mb-3 flex items-center gap-1.5">
        <Award className="w-3.5 h-3.5 text-amber-400" /> Unlocked Achievement Badges
      </h2>
      <div className="grid grid-cols-2 gap-2.5">
        {achievements.map((ach, idx) => (
          <div key={idx} className="bg-gray-950/80 rounded-2xl p-3 border border-gray-800 flex items-center gap-3">
            <div className="text-xl p-2 rounded-xl bg-gray-900 border border-gray-800">{ach.icon}</div>
            <div>
              <div className="font-black text-xs text-white">{ach.name}</div>
              <div className="text-[10px] text-gray-400 leading-tight mt-0.5">{ach.desc}</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
