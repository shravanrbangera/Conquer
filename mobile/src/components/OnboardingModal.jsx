import React, { useState } from 'react';
import { ArrowRight } from 'lucide-react';
import ThreeGlobe from './3d/ThreeGlobe';
import ThreeShield from './3d/ThreeShield';

export default function OnboardingModal({ onComplete }) {
  const [step, setStep] = useState(0);

  const slides = [
    {
      title: 'WALK',
      subtitle: 'Every step expands your world.',
      description: 'Turn your daily movement into real-world geographic territory. CONQUER tracks your precise physical path on a living 3D map.',
      modelType: 'globe',
      accentColor: 'from-cyan-500 to-blue-600'
    },
    {
      title: 'CONQUER',
      subtitle: 'Complete a loop to claim the land.',
      description: 'Return within 10 meters of your start location to form a closed circuit. The enclosed real-world area becomes your territory.',
      modelType: 'shieldGreen',
      accentColor: 'from-emerald-500 to-teal-600'
    },
    {
      title: 'DEFEND',
      subtitle: 'Defend your empire against rival players.',
      description: 'Other users can walk overlapping loops to capture your land. Defend your borders and expand your territory empire!',
      modelType: 'shieldRed',
      accentColor: 'from-rose-600 to-red-600'
    }
  ];

  const currentSlide = slides[step];

  const handleNext = () => {
    if (step < slides.length - 1) {
      setStep(step + 1);
    } else {
      onComplete();
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-navy-950/95 backdrop-blur-2xl">
      <div className="w-full max-w-sm cyber-glass rounded-3xl p-6 text-center border border-cyan-500/40 shadow-2xl flex flex-col items-center relative overflow-hidden">
        
        {/* 3D WebGL Model Canvas Container */}
        <div className="relative w-48 h-48 flex items-center justify-center mb-2">
          <div className="absolute inset-0 bg-cyan-500/10 rounded-full blur-3xl pointer-events-none"></div>
          {currentSlide.modelType === 'globe' && <ThreeGlobe width={200} height={200} />}
          {currentSlide.modelType === 'shieldGreen' && <ThreeShield width={180} height={180} color={0x00FF9D} />}
          {currentSlide.modelType === 'shieldRed' && <ThreeShield width={180} height={180} color={0xFF0055} />}
        </div>

        <h2 className="font-heading font-black text-3xl tracking-tight text-white mb-1">
          {currentSlide.title}
        </h2>
        
        <p className="text-xs font-bold text-cyan-400 mb-3 font-heading">
          {currentSlide.subtitle}
        </p>

        <p className="text-xs text-gray-300 leading-relaxed mb-6 px-2">
          {currentSlide.description}
        </p>

        {/* Step Indicators */}
        <div className="flex items-center gap-2 mb-6">
          {slides.map((_, idx) => (
            <div
              key={idx}
              className={`h-2 rounded-full transition-all duration-300 ${
                idx === step ? 'w-8 bg-cyan-400 glow-cyan-lg' : 'w-2 bg-gray-800'
              }`}
            />
          ))}
        </div>

        <button
          onClick={handleNext}
          className="w-full py-4 px-6 rounded-2xl bg-gradient-to-r from-cyan-500 to-blue-600 hover:from-cyan-400 hover:to-blue-500 text-white font-black text-sm tracking-wider glow-cyan-lg flex items-center justify-center gap-2 transition"
        >
          {step === slides.length - 1 ? 'START CONQUERING' : 'NEXT'} <ArrowRight className="w-4 h-4" />
        </button>

      </div>
    </div>
  );
}
