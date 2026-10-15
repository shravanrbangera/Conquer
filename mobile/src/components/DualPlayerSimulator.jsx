import React from 'react';
import { Play, RotateCcw, AlertTriangle, Users, Sparkles } from 'lucide-react';

export default function DualPlayerSimulator({
  onRunShravanLoop,
  onRunRahulAttack,
  onResetSimulation,
  attackAlert = null
}) {
  return (
    <div className="glass-panel rounded-3xl p-4 border border-cyan-500/30 flex flex-col gap-3 shadow-2xl">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Sparkles className="w-4 h-4 text-cyan-400" />
          <span className="font-heading font-black text-xs text-white tracking-wider uppercase">
            Live Territory Capture Simulator
          </span>
        </div>
        <span className="text-[10px] px-2.5 py-0.5 rounded-full bg-cyan-950/80 text-cyan-300 font-extrabold border border-cyan-700/60">
          V1 MVP Engine
        </span>
      </div>

      {/* Attack Alert Notification Banner */}
      {attackAlert && (
        <div className="bg-red-950/90 border-2 border-red-500 rounded-2xl p-3.5 text-red-200 flex items-center gap-3 animate-pulse shadow-lg shadow-red-950">
          <AlertTriangle className="w-6 h-6 text-red-400 shrink-0" />
          <div className="text-xs">
            <div className="font-black text-red-100">{attackAlert.title}</div>
            <div className="text-red-200/90">{attackAlert.message}</div>
          </div>
        </div>
      )}

      {/* Simulation Action Triggers */}
      <div className="grid grid-cols-2 gap-2.5">
        <button
          onClick={onRunShravanLoop}
          className="p-3.5 rounded-2xl bg-gradient-to-br from-blue-950/90 to-blue-900/60 hover:from-blue-900 hover:to-blue-800 border border-blue-500/60 text-left transition glass-card-hover"
        >
          <div className="text-[10px] font-black text-blue-400 uppercase tracking-wider flex items-center gap-1">
            <Play className="w-3 h-3 fill-current" /> Step 1: Shravan
          </div>
          <div className="text-sm font-black text-white font-heading my-0.5">Conquer 1.82 km²</div>
          <div className="text-[10px] text-blue-300/80">Claims Blue Empire</div>
        </button>

        <button
          onClick={onRunRahulAttack}
          className="p-3.5 rounded-2xl bg-gradient-to-br from-red-950/90 to-rose-900/60 hover:from-red-900 hover:to-rose-800 border border-red-500/60 text-left transition glass-card-hover"
        >
          <div className="text-[10px] font-black text-red-400 uppercase tracking-wider flex items-center gap-1">
            <Play className="w-3 h-3 fill-current" /> Step 2: Rahul Attack
          </div>
          <div className="text-sm font-black text-white font-heading my-0.5">Capture Overlap</div>
          <div className="text-[10px] text-red-300/80">Steals 0.32 km² Red</div>
        </button>
      </div>

      <button
        onClick={onResetSimulation}
        className="w-full py-2.5 px-3 rounded-xl bg-gray-900/90 hover:bg-gray-800 text-gray-400 text-xs font-bold flex items-center justify-center gap-1.5 border border-gray-800 transition"
      >
        <RotateCcw className="w-3.5 h-3.5" /> Reset Map State
      </button>
    </div>
  );
}
