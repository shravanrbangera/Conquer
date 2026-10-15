import React, { useRef } from 'react';
import { useFrame } from '@react-three/fiber';
import * as THREE from 'three';

export default function GodRays({ count = 6 }) {
  const groupRef = useRef();

  useFrame((state) => {
    if (!groupRef.current) return;
    const time = state.clock.getElapsedTime();

    // Animate god ray light intensity & sway
    groupRef.current.children.forEach((ray, i) => {
      ray.rotation.z = Math.sin(time * 0.5 + i) * 0.08;
      ray.material.opacity = 0.15 + Math.sin(time * 1.2 + i * 2) * 0.08;
    });
  });

  return (
    <group ref={groupRef} position={[0, 10, -5]}>
      {Array.from({ length: count }).map((_, i) => {
        const xPos = (i - count / 2) * 3.5;
        const angle = (i - count / 2) * 0.1;

        return (
          <mesh
            key={i}
            position={[xPos, 0, (i % 2) * -2]}
            rotation={[0, 0, angle]}
          >
            <coneGeometry args={[2.5, 22, 16, 1, true]} />
            <meshBasicMaterial
              color="#00F0FF"
              transparent
              opacity={0.2}
              blending={THREE.AdditiveBlending}
              side={THREE.DoubleSide}
              depthWrite={false}
            />
          </mesh>
        );
      })}
    </group>
  );
}
