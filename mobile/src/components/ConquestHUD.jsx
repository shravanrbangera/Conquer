import React from 'react';
import { Play, Pause, Square, ShieldCheck, Navigation, Activity, Zap, Compass, Flame } from 'lucide-react';

export default function ConquestHUD({
  elapsedSeconds = 0,
  distanceMeters = 0,
  steps = 0,
  speedKmH = 0,
  isPaused = false,
  loopStatus = {},
  onPauseToggle,
  onEndConquest
}) {
  const formatTime = (totalSeconds) => {
    const mins = Math.floor(totalSeconds / 60);
    const secs = totalSeconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  };

  const distanceKm = (distanceMeters / 1000).toFixed(2);
  const isValidLoop = loopStatus.isValid;

  // Calculate loop proximity percentage (0 - 100%)
  let proximityPercent = Math.min(100, Math.round((distanceMeters / 100) * 100));
  if (isValidLoop) proximityPercent = 100;

  return (
    <div className="absolute top-4 left-4 right-4 z-10 flex flex-col gap-3 pointer-events-none">
      {/* Top Telemetry Header Card */}
      <div className="cyber-glass rounded-3xl p-4 pointer-events-auto flex items-center justify-between border-l-4 border-cyan-400 shadow-2xl">
        <div className="flex items-center gap-3">
          <div className="relative w-13 h-13 rounded-2xl bg-gradient-to-tr from-cyan-500/30 to-blue-600/20 border border-cyan-400/50 flex items-center justify-center text-cyan-300 font-bold text-2xl shadow-lg glow-cyan-lg">
            ⚔️
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="font-heading font-black text-[10px] tracking-widest uppercase text-cyan-400">
                Conquest Active
              </span>
              <span className="inline-block w-2.5 h-2.5 rounded-full bg-emerald-400 animate-ping"></span>
            </div>
            <div className="text-3xl font-black font-heading text-white tracking-tight">
              {formatTime(elapsedSeconds)}
            </div>
          </div>
        </div>

        {/* Live Loop Proximity Gauge */}
        <div className="flex flex-col items-end">
          <div className="text-[10px] text-gray-400 uppercase tracking-widest font-extrabold flex items-center gap-1">
            <Compass className="w-3 h-3 text-cyan-400 animate-spin" style={{ animationDuration: '10s' }} /> Loop Closure
          </div>
          <div className="text-lg font-black text-cyan-300 font-heading flex items-center gap-1">
            {proximityPercent}% <span className="text-xs text-gray-400 font-normal">Closed</span>
          </div>
        </div>
      </div>

      {/* Loop Status Banner */}
      <div className="pointer-events-auto">
        {isValidLoop ? (
          <div className="bg-gradient-to-r from-emerald-950 via-teal-900 to-emerald-950 backdrop-blur-xl border-2 border-emerald-400 text-white rounded-2xl p-4 flex items-center gap-3.5 shadow-2xl shadow-emerald-950 animate-bounce">
            <ShieldCheck className="w-8 h-8 text-emerald-300 shrink-0 fill-current" />
            <div>
              <div className="font-heading font-black text-sm text-emerald-100 tracking-wide">
                VALID CLOSED LOOP DETECTED!
              </div>
              <div className="text-xs text-emerald-200">
                Return distance: {loopStatus.returnDistance?.toFixed(1)}m. Click Claim Land to annex territory!
              </div>
            </div>
          </div>
        ) : (
          <div className="cyber-glass rounded-2xl p-3.5 flex items-center gap-3 text-gray-300">
            <Navigation className="w-5 h-5 text-cyan-400 shrink-0 animate-spin" style={{ animationDuration: '6s' }} />
            <div className="text-xs">
              <span className="font-extrabold text-white">Rule Checklist: </span>
              {loopStatus.reason || 'Walk a closed loop (min 100m) and return within 10m of start.'}
            </div>
          </div>
        )}
      </div>

      {/* Bottom Floating Stats Bar */}
      <div className="fixed bottom-20 left-4 right-4 pointer-events-auto cyber-glass rounded-3xl p-4 flex flex-col gap-3 shadow-2xl">
        <div className="grid grid-cols-3 gap-2 text-center">
          <div className="bg-gray-950/80 rounded-2xl p-3 border border-gray-800">
            <div className="text-[10px] text-gray-400 font-semibold uppercase">Distance</div>
            <div className="text-lg font-black text-white font-heading">{distanceKm} <span className="text-xs font-normal text-gray-400">km</span></div>
          </div>

          <div className="bg-gray-950/80 rounded-2xl p-3 border border-gray-800">
            <div className="text-[10px] text-gray-400 font-semibold uppercase">Speed</div>
            <div className="text-lg font-black text-emerald-400 font-heading">{speedKmH.toFixed(1)} <span className="text-xs font-normal text-gray-400">km/h</span></div>
          </div>

          <div className="bg-gray-950/80 rounded-2xl p-3 border border-gray-800">
            <div className="text-[10px] text-gray-400 font-semibold uppercase">Steps</div>
            <div className="text-lg font-black text-cyan-400 font-heading">{steps.toLocaleString()}</div>
          </div>
        </div>

        {/* Action Controls */}
        <div className="grid grid-cols-2 gap-3 pt-1">
          <button
            onClick={onPauseToggle}
            className="w-full py-4 px-4 rounded-2xl bg-gray-900 hover:bg-gray-800 text-white font-black text-xs tracking-wider flex items-center justify-center gap-2 border border-gray-700 transition shadow-lg"
          >
            {isPaused ? <Play className="w-4 h-4 text-emerald-400 fill-current" /> : <Pause className="w-4 h-4 text-amber-400 fill-current" />}
            {isPaused ? 'RESUME' : 'PAUSE'}
          </button>

          <button
            onClick={onEndConquest}
            className={`w-full py-4 px-4 rounded-2xl font-black text-xs tracking-wider flex items-center justify-center gap-2 text-white transition ${
              isValidLoop
                ? 'bg-gradient-to-r from-emerald-500 to-teal-600 hover:from-emerald-400 hover:to-teal-500 glow-emerald-lg'
                : 'bg-gradient-to-r from-red-600 to-rose-700 hover:from-red-500 hover:to-rose-600 glow-crimson-lg'
            }`}
          >
            <Square className="w-4 h-4 fill-current" />
            {isValidLoop ? 'CLAIM LAND' : 'END CONQUEST'}
          </button>
        </div>
      </div>
    </div>
  );
}
