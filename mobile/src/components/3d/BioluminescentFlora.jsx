import React, { useRef, useMemo } from 'react';
import { useFrame } from '@react-three/fiber';
import * as THREE from 'three';

export default function BioluminescentFlora() {
  const kelpGroupRef = useRef();
  const coralsGroupRef = useRef();

  // Create kelp strands
  const kelpStrands = useMemo(() => {
    const temp = [];
    for (let i = 0; i < 28; i++) {
      const x = (Math.random() - 0.5) * 24;
      const z = (Math.random() - 0.5) * 16 - 2;
      const height = Math.random() * 4 + 3;
      const color = i % 2 === 0 ? '#00FF9D' : '#00F0FF';
      temp.push({ x, z, height, color, phase: Math.random() * Math.PI * 2 });
    }
    return temp;
  }, []);

  // Create bioluminescent coral/crystal nodes
  const corals = useMemo(() => {
    const temp = [];
    const colors = ['#00F0FF', '#00FF9D', '#FF0055', '#B026FF', '#FFD700'];
    for (let i = 0; i < 20; i++) {
      const x = (Math.random() - 0.5) * 22;
      const z = (Math.random() - 0.5) * 14 - 1;
      const scale = Math.random() * 0.6 + 0.4;
      const color = colors[i % colors.length];
      temp.push({ x, z, scale, color, phase: Math.random() * Math.PI });
    }
    return temp;
  }, []);

  useFrame((state) => {
    const time = state.clock.getElapsedTime();

    // Natural flowing underwater sway animation for kelp
    if (kelpGroupRef.current) {
      kelpGroupRef.current.children.forEach((mesh, i) => {
        const strand = kelpStrands[i];
        if (strand) {
          mesh.rotation.z = Math.sin(time * 1.5 + strand.phase) * 0.18;
          mesh.rotation.x = Math.cos(time * 1.2 + strand.phase) * 0.12;
        }
      });
    }

    // Pulsating bioluminescent emissive glow on corals
    if (coralsGroupRef.current) {
      coralsGroupRef.current.children.forEach((mesh, i) => {
        const coral = corals[i];
        if (coral && mesh.material) {
          mesh.material.emissiveIntensity = 0.4 + Math.sin(time * 2 + coral.phase) * 0.35;
        }
      });
    }
  });

  return (
    <group position={[0, -5, 0]}>
      {/* Seafloor Terrain Plane */}
      <mesh rotation={[-Math.PI / 2, 0, 0]} position={[0, -0.2, 0]}>
        <planeGeometry args={[40, 40, 32, 32]} />
        <meshStandardMaterial
          color="#031024"
          roughness={0.9}
          metalness={0.2}
          wireframe={false}
        />
      </mesh>

      {/* Swaying Kelp Flora Group */}
      <group ref={kelpGroupRef}>
        {kelpStrands.map((k, i) => (
          <mesh key={i} position={[k.x, k.height / 2, k.z]}>
            <cylinderGeometry args={[0.08, 0.25, k.height, 12]} />
            <meshStandardMaterial
              color={k.color}
              emissive={k.color}
              emissiveIntensity={0.3}
              roughness={0.3}
            />
          </mesh>
        ))}
      </group>

      {/* Pulsating Bioluminescent Corals & Crystals */}
      <group ref={coralsGroupRef}>
        {corals.map((c, i) => (
          <mesh key={i} position={[c.x, c.scale * 0.6, c.z]} scale={c.scale}>
            <dodecahedronGeometry args={[0.9, 0]} />
            <meshStandardMaterial
              color={c.color}
              emissive={c.color}
              emissiveIntensity={0.5}
              roughness={0.1}
              metalness={0.9}
            />
          </mesh>
        ))}
      </group>
    </group>
  );
}
