import React, { useEffect, useRef } from 'react';
import { ShieldCheck, Zap, Coins, ArrowRight } from 'lucide-react';
import ThreeTrophy from './3d/ThreeTrophy';

export default function VictoryModal({ conquestData, onClose }) {
  const canvasRef = useRef(null);

  useEffect(() => {
    // Particle Confetti Effect
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;

    const particles = [];
    const colors = ['#00F0FF', '#00FF9D', '#FFD700', '#B026FF', '#FF0055'];

    for (let i = 0; i < 90; i++) {
      particles.push({
        x: canvas.width / 2,
        y: canvas.height / 2 - 80,
        vx: (Math.random() - 0.5) * 14,
        vy: (Math.random() - 0.75) * 16,
        size: Math.random() * 8 + 4,
        color: colors[Math.floor(Math.random() * colors.length)],
        alpha: 1,
        rotation: Math.random() * 360,
        spin: (Math.random() - 0.5) * 12
      });
    }

    let animationFrameId;
    const render = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      particles.forEach((p) => {
        p.x += p.vx;
        p.y += p.vy;
        p.vy += 0.28;
        p.alpha -= 0.01;
        p.rotation += p.spin;

        if (p.alpha > 0) {
          ctx.save();
          ctx.translate(p.x, p.y);
          ctx.rotate((p.rotation * Math.PI) / 180);
          ctx.globalAlpha = Math.max(0, p.alpha);
          ctx.fillStyle = p.color;
          ctx.fillRect(-p.size / 2, -p.size / 2, p.size, p.size);
          ctx.restore();
        }
      });

      if (particles.some(p => p.alpha > 0)) {
        animationFrameId = requestAnimationFrame(render);
      }
    };

    render();

    return () => cancelAnimationFrame(animationFrameId);
  }, []);

  if (!conquestData) return null;
  const { areaKm2 = 1.82, distanceKm = 3.84, steps = 5212, xp = 420, coins = 85 } = conquestData;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-navy-950/90 backdrop-blur-2xl">
      <canvas ref={canvasRef} className="absolute inset-0 pointer-events-none z-10" />

      <div className="relative z-20 w-full max-w-sm cyber-glass rounded-3xl p-6 text-center border-2 border-cyan-500/70 shadow-2xl animate-victory-pop overflow-hidden">
        
        {/* Glowing backdrop aura */}
        <div className="absolute -top-16 left-1/2 -translate-x-1/2 w-48 h-48 rounded-full bg-gradient-to-tr from-cyan-500/30 via-gold-500/30 to-purple-600/30 blur-3xl pointer-events-none"></div>

        {/* 3D WebGL Gold Trophy Model */}
        <div className="relative mx-auto w-36 h-36 flex items-center justify-center -mt-2 -mb-2">
          <ThreeTrophy width={160} height={160} />
        </div>

        <h2 className="font-heading font-black text-2xl tracking-tight text-white mb-0.5">
          TERRITORY CONQUERED!
        </h2>
        <p className="text-xs uppercase tracking-widest text-cyan-400 font-extrabold mb-3">
          YOU OWN THIS LAND
        </p>

        {/* Main Territory Area Card */}
        <div className="bg-gradient-to-r from-blue-950/90 via-cyan-900/50 to-blue-950/90 rounded-2xl p-3.5 border border-cyan-400/50 mb-4 shadow-inner">
          <div className="text-[10px] text-cyan-200 uppercase font-black tracking-widest">New Empire Territory Annexed</div>
          <div className="text-3xl font-black font-heading gradient-gold-text my-0.5 drop-shadow-lg">
            +{areaKm2.toFixed(2)} <span className="text-base font-bold text-yellow-300">km²</span>
          </div>
          <div className="text-[11px] text-emerald-400 font-bold flex items-center justify-center gap-1">
            <ShieldCheck className="w-3.5 h-3.5" /> Geodesic Closed Boundary Recorded
          </div>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-2 gap-2 mb-4 text-left">
          <div className="bg-gray-950/80 rounded-2xl p-2.5 border border-gray-800">
            <div className="text-[10px] text-gray-400 uppercase font-semibold">Distance</div>
            <div className="text-sm font-black text-white">{distanceKm.toFixed(2)} km</div>
          </div>
          <div className="bg-gray-950/80 rounded-2xl p-2.5 border border-gray-800">
            <div className="text-[10px] text-gray-400 uppercase font-semibold">Steps</div>
            <div className="text-sm font-black text-white">{steps.toLocaleString()}</div>
          </div>
        </div>

        {/* Rewards Row */}
        <div className="flex items-center justify-around bg-gray-950/90 rounded-2xl p-3 border border-gray-800 mb-5">
          <div className="flex items-center gap-2">
            <Zap className="w-4 h-4 text-amber-400 fill-current" />
            <div className="text-left">
              <div className="text-[9px] text-gray-400 uppercase font-semibold">XP Earned</div>
              <div className="text-xs font-black text-amber-400 font-heading">+{xp} XP</div>
            </div>
          </div>

          <div className="h-6 w-px bg-gray-800"></div>

          <div className="flex items-center gap-2">
            <Coins className="w-4 h-4 text-yellow-400 fill-current" />
            <div className="text-left">
              <div className="text-[9px] text-gray-400 uppercase font-semibold">Coins</div>
              <div className="text-xs font-black text-yellow-400 font-heading">+{coins}</div>
            </div>
          </div>
        </div>

        {/* Return Button */}
        <button
          onClick={onClose}
          className="w-full py-3.5 px-6 rounded-2xl bg-gradient-to-r from-cyan-500 via-blue-600 to-indigo-600 hover:from-cyan-400 hover:to-indigo-500 text-white font-black text-xs tracking-wider glow-cyan-lg flex items-center justify-center gap-2 transition"
        >
          RETURN TO MAP <ArrowRight className="w-4 h-4" />
        </button>

      </div>
    </div>
  );
}
