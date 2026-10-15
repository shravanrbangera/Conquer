import React, { useRef } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { PerspectiveCamera, OrbitControls } from '@react-three/drei';
import * as THREE from 'three';

import GodRays from './GodRays';
import BioluminescentFlora from './BioluminescentFlora';
import MarineSnowAndBubbles from './MarineSnowAndBubbles';
import UnderwaterPostProcessing from './UnderwaterPostProcessing';

function UnderwaterEnvironment({ depthLevel = 0 }) {
  const cameraRef = useRef();

  useFrame((state) => {
    if (!cameraRef.current) return;
    const { pointer, clock } = state;
    const time = clock.getElapsedTime();

    // Buoyancy camera drift inertia (subtle vertical floating)
    const buoyancy = Math.sin(time * 0.8) * 0.25;

    // Mouse fluid disturbance parallax
    const targetX = pointer.x * 1.2;
    const targetY = -depthLevel * 3 + pointer.y * 0.8 + buoyancy;

    cameraRef.current.position.x += (targetX - cameraRef.current.position.x) * 0.04;
    cameraRef.current.position.y += (targetY - cameraRef.current.position.y) * 0.04;
  });

  return (
    <>
      <PerspectiveCamera ref={cameraRef} makeDefault position={[0, 0, 10]} fov={50} />

      {/* Deep-Sea Exponential Fog */}
      <fogExp2 attach="fog" args={['#021329', 0.038]} />

      {/* Deep Ocean Lighting */}
      <ambientLight intensity={0.4} color="#00E5FF" />
      <directionalLight position={[0, 12, 5]} intensity={2.2} color="#00F0FF" />
      <pointLight position={[0, -4, 0]} intensity={3} color="#00FF9D" />
      <pointLight position={[-6, 2, -2]} intensity={2} color="#B026FF" />

      {/* 1. Volumetric Sun Shafts (God Rays) */}
      <GodRays count={7} />

      {/* 2. Seafloor Bioluminescent Corals & Kelp Flora */}
      <BioluminescentFlora />

      {/* 3. Rising Bubbles & Marine Snow Particle Current */}
      <MarineSnowAndBubbles bubbleCount={60} snowCount={1200} />

      {/* 4. Underwater Postprocessing Filters */}
      <UnderwaterPostProcessing />
    </>
  );
}

export default function UnderwaterScene({ depthLevel = 0 }) {
  return (
    <div className="w-full h-full absolute inset-0 z-0">
      <Canvas
        dpr={[1, 2]}
        gl={{ antialias: true, alpha: false, powerPreference: 'high-performance' }}
      >
        <color attach="background" args={['#021329']} />
        <UnderwaterEnvironment depthLevel={depthLevel} />
        <OrbitControls enableZoom={false} enablePan={false} rotateSpeed={0.3} maxPolarAngle={Math.PI / 2 + 0.1} />
      </Canvas>
    </div>
  );
}
