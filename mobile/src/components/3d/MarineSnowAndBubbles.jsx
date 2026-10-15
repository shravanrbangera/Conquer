import React, { useRef, useMemo } from 'react';
import { useFrame } from '@react-three/fiber';
import * as THREE from 'three';

export default function MarineSnowAndBubbles({ bubbleCount = 60, snowCount = 1000 }) {
  const bubblesMeshRef = useRef();
  const snowPointsRef = useRef();
  const dummy = useMemo(() => new THREE.Object3D(), []);

  // Rising Bubble Emitter data
  const bubbles = useMemo(() => {
    const temp = [];
    for (let i = 0; i < bubbleCount; i++) {
      temp.push({
        x: (Math.random() - 0.5) * 18,
        y: (Math.random() - 0.5) * 12 - 4,
        z: (Math.random() - 0.5) * 12,
        scale: Math.random() * 0.12 + 0.04,
        speedY: Math.random() * 0.03 + 0.015,
        wobbleSpeed: Math.random() * 2 + 1,
        wobbleScale: Math.random() * 0.15 + 0.05
      });
    }
    return temp;
  }, [bubbleCount]);

  // Floating Marine Snow micro-particle positions
  const snowPositions = useMemo(() => {
    const pos = new Float32Array(snowCount * 3);
    for (let i = 0; i < snowCount; i++) {
      pos[i * 3] = (Math.random() - 0.5) * 30;
      pos[i * 3 + 1] = (Math.random() - 0.5) * 20;
      pos[i * 3 + 2] = (Math.random() - 0.5) * 20;
    }
    return pos;
  }, [snowCount]);

  useFrame((state) => {
    const time = state.clock.getElapsedTime();

    // 1. Animate Rising Bubbles with lateral wobble
    if (bubblesMeshRef.current) {
      bubbles.forEach((b, i) => {
        b.y += b.speedY;
        // Loop back to bottom when reaching surface
        if (b.y > 7) b.y = -5;

        const currentX = b.x + Math.sin(time * b.wobbleSpeed + i) * b.wobbleScale;

        dummy.position.set(currentX, b.y, b.z);
        dummy.scale.set(b.scale, b.scale, b.scale);
        dummy.updateMatrix();

        bubblesMeshRef.current.setMatrixAt(i, dummy.matrix);
      });
      bubblesMeshRef.current.instanceMatrix.needsUpdate = true;
    }

    // 2. Animate Marine Snow current drift
    if (snowPointsRef.current) {
      snowPointsRef.current.rotation.y = time * 0.015;
      snowPointsRef.current.rotation.z = Math.sin(time * 0.2) * 0.05;
    }
  });

  return (
    <group>
      {/* Instanced Mesh Rising Bubbles */}
      <instancedMesh ref={bubblesMeshRef} args={[null, null, bubbleCount]}>
        <sphereGeometry args={[1, 16, 16]} />
        <meshPhysicalMaterial
          color="#00F0FF"
          transmission={0.9}
          roughness={0.05}
          ior={1.1}
          transparent
          opacity={0.7}
        />
      </instancedMesh>

      {/* Floating Marine Snow Micro-Particles */}
      <points ref={snowPointsRef}>
        <bufferGeometry>
          <bufferAttribute
            attach="attributes-position"
            count={snowCount}
            array={snowPositions}
            itemSize={3}
          />
        </bufferGeometry>
        <pointsMaterial
          size={0.07}
          color="#A5F3FC"
          transparent
          opacity={0.45}
          blending={THREE.AdditiveBlending}
          depthWrite={false}
        />
      </points>
    </group>
  );
}
