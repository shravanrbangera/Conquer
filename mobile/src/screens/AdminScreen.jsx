import React, { useState } from 'react';
import { ShieldAlert, Sliders, Users, Map, Activity, CheckCircle, Save, AlertOctagon, Terminal } from 'lucide-react';

export default function AdminScreen() {
  const [settings, setSettings] = useState({
    minLoopDistanceMeters: 100,
    returnToleranceMeters: 10,
    dailyStepGoal: 2000,
    maxRunningSpeedKmH: 20,
    xpPerKm: 50,
    coinsPerConquest: 30
  });

  const [saveSuccess, setSaveSuccess] = useState(false);

  const fraudLogs = [
    { id: 'f1', username: 'GHOST_RUNNER', trustScore: 35, status: 'rejected', issue: 'GPS Teleportation (500m in 1s)' },
    { id: 'f2', username: 'SPEED_RACER', trustScore: 60, status: 'suspicious', issue: 'Speed 45 km/h (Vehicle detected)' },
    { id: 'f3', username: 'SHRAVAN', trustScore: 98, status: 'passed', issue: 'Clean Human Walk' }
  ];

  const handleSave = (e) => {
    e.preventDefault();
    setSaveSuccess(true);
    setTimeout(() => setSaveSuccess(false), 3000);
  };

  return (
    <div className="flex flex-col h-full bg-navy-950 text-white p-4 pb-24 overflow-y-auto ambient-bg">
      <div className="flex items-center justify-between mb-4">
        <div>
          <h1 className="font-heading font-black text-2xl text-white tracking-tight flex items-center gap-2">
            <Terminal className="w-6 h-6 text-purple-400" /> ADMIN COMMAND CENTER
          </h1>
          <p className="text-xs text-purple-300">Live game configuration & anti-cheat threat telemetry</p>
        </div>
      </div>

      {/* System Telemetry Metrics */}
      <div className="grid grid-cols-2 gap-3 mb-6">
        <div className="cyber-glass rounded-2xl p-4 border border-purple-500/40 glow-purple">
          <div className="text-[10px] text-gray-400 font-semibold uppercase">Total Players</div>
          <div className="text-2xl font-black text-purple-300 font-heading my-0.5">12,482</div>
          <div className="text-[10px] text-emerald-400 font-extrabold">4,821 Active Today</div>
        </div>

        <div className="cyber-glass rounded-2xl p-4 border border-cyan-500/40 glow-cyan-lg">
          <div className="text-[10px] text-gray-400 font-semibold uppercase">Total Conquests</div>
          <div className="text-2xl font-black text-cyan-300 font-heading my-0.5">8,932</div>
          <div className="text-[10px] text-cyan-400 font-extrabold">482 km² Land Mapped</div>
        </div>
      </div>

      {/* Dynamic Game Configuration Panel */}
      <div className="cyber-glass rounded-3xl p-5 border border-gray-800 mb-6">
        <h2 className="font-heading font-black text-base text-white mb-4 flex items-center gap-2">
          <Sliders className="w-4 h-4 text-cyan-400" /> Dynamic Game Engine Parameters
        </h2>

        {saveSuccess && (
          <div className="bg-emerald-950 border border-emerald-500 text-emerald-300 text-xs rounded-2xl p-3.5 mb-4 flex items-center gap-2 animate-bounce">
            <CheckCircle className="w-4 h-4" /> Parameters updated dynamically across backend server!
          </div>
        )}

        <form onSubmit={handleSave} className="flex flex-col gap-4">
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs text-gray-400 font-semibold mb-1 block">Min Loop Distance (m)</label>
              <input
                type="number"
                value={settings.minLoopDistanceMeters}
                onChange={(e) => setSettings({ ...settings, minLoopDistanceMeters: Number(e.target.value) })}
                className="w-full p-3 rounded-2xl bg-gray-950 border border-gray-800 text-sm text-white font-black focus:border-cyan-500 transition"
              />
            </div>

            <div>
              <label className="text-xs text-gray-400 font-semibold mb-1 block">Return Tolerance (m)</label>
              <input
                type="number"
                value={settings.returnToleranceMeters}
                onChange={(e) => setSettings({ ...settings, returnToleranceMeters: Number(e.target.value) })}
                className="w-full p-3 rounded-2xl bg-gray-950 border border-gray-800 text-sm text-white font-black focus:border-cyan-500 transition"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="text-xs text-gray-400 font-semibold mb-1 block">Max Speed Cap (km/h)</label>
              <input
                type="number"
                value={settings.maxRunningSpeedKmH}
                onChange={(e) => setSettings({ ...settings, maxRunningSpeedKmH: Number(e.target.value) })}
                className="w-full p-3 rounded-2xl bg-gray-950 border border-gray-800 text-sm text-white font-black focus:border-cyan-500 transition"
              />
            </div>

            <div>
              <label className="text-xs text-gray-400 font-semibold mb-1 block">Daily Step Goal</label>
              <input
                type="number"
                value={settings.dailyStepGoal}
                onChange={(e) => setSettings({ ...settings, dailyStepGoal: Number(e.target.value) })}
                className="w-full p-3 rounded-2xl bg-gray-950 border border-gray-800 text-sm text-white font-black focus:border-cyan-500 transition"
              />
            </div>
          </div>

          <button
            type="submit"
            className="w-full py-4 px-4 rounded-2xl bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-500 hover:to-indigo-500 text-white font-black text-xs tracking-wider flex items-center justify-center gap-2 transition glow-purple shadow-xl"
          >
            <Save className="w-4 h-4" /> SAVE ENGINE CONFIGURATION
          </button>
        </form>
      </div>

      {/* Anti-Cheat Audit Logs */}
      <h2 className="font-heading font-extrabold text-xs text-gray-400 uppercase tracking-widest mb-3 flex items-center gap-1.5">
        <ShieldAlert className="w-4 h-4 text-red-400" /> Anti-Cheat Threat Audit Logs
      </h2>
      <div className="flex flex-col gap-2.5">
        {fraudLogs.map((log) => (
          <div key={log.id} className="bg-gray-950/80 rounded-2xl p-3.5 border border-gray-800 flex items-center justify-between">
            <div>
              <div className="font-black text-sm text-white flex items-center gap-2">
                {log.username}
                <span className={`text-[9px] px-2 py-0.5 rounded-full font-black uppercase ${
                  log.status === 'passed' ? 'bg-emerald-950 text-emerald-400 border border-emerald-800' :
                  log.status === 'suspicious' ? 'bg-amber-950 text-amber-400 border border-amber-800' : 'bg-red-950 text-red-400 border border-red-800'
                }`}>
                  Trust: {log.trustScore}%
                </span>
              </div>
              <div className="text-xs text-gray-400 mt-1">{log.issue}</div>
            </div>

            <button className="text-xs px-3 py-1.5 rounded-xl bg-gray-900 hover:bg-gray-800 text-gray-300 font-extrabold border border-gray-700">
              Audit
            </button>
          </div>
        ))}
      </div>
    </div>
  );
}
