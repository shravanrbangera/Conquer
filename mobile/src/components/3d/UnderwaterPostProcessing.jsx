import React from 'react';
import { EffectComposer, Bloom, ChromaticAberration, Noise } from '@react-three/postprocessing';
import { Vector2 } from 'three';

export default function UnderwaterPostProcessing() {
  return (
    <EffectComposer disableNormalPass>
      <Bloom
        luminanceThreshold={0.35}
        luminanceSmoothing={0.8}
        height={300}
        intensity={1.4}
      />
      <ChromaticAberration offset={new Vector2(0.002, 0.002)} />
      <Noise opacity={0.035} />
    </EffectComposer>
  );
}
