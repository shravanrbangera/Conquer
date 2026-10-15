import React, { useEffect, useRef } from 'react';
import * as THREE from 'three';

export default function ThreeTrophy({ width = 200, height = 200 }) {
  const mountRef = useRef(null);

  useEffect(() => {
    const mountNode = mountRef.current;
    if (!mountNode) return;

    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(45, width / height, 0.1, 1000);
    camera.position.set(0, 0.5, 4);

    const renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true });
    renderer.setSize(width, height);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    mountNode.appendChild(renderer.domElement);

    const trophyGroup = new THREE.Group();

    // Metallic Gold Material
    const goldMat = new THREE.MeshStandardMaterial({
      color: 0xFFD700,
      metalness: 0.95,
      roughness: 0.15,
      emissive: 0x332200
    });

    // Base Octagon
    const baseGeo = new THREE.CylinderGeometry(0.8, 0.9, 0.3, 8);
    const baseMat = new THREE.MeshStandardMaterial({ color: 0x111827, metalness: 0.8, roughness: 0.2 });
    const base = new THREE.Mesh(baseGeo, baseMat);
    base.position.y = -1;
    trophyGroup.add(base);

    // Stem
    const stemGeo = new THREE.CylinderGeometry(0.2, 0.35, 0.6, 16);
    const stem = new THREE.Mesh(stemGeo, goldMat);
    stem.position.y = -0.55;
    trophyGroup.add(stem);

    // Cup Body
    const cupGeo = new THREE.CylinderGeometry(0.75, 0.35, 1.1, 24, 1, true);
    const cup = new THREE.Mesh(cupGeo, goldMat);
    cup.position.y = 0.2;
    trophyGroup.add(cup);

    // Cup Bottom Cap
    const capGeo = new THREE.CylinderGeometry(0.35, 0.1, 0.2, 24);
    const cap = new THREE.Mesh(capGeo, goldMat);
    cap.position.y = -0.3;
    trophyGroup.add(cap);

    // Handles (Torus)
    const handleGeo = new THREE.TorusGeometry(0.4, 0.08, 12, 24, Math.PI * 1.2);
    
    const handleLeft = new THREE.Mesh(handleGeo, goldMat);
    handleLeft.position.set(-0.7, 0.3, 0);
    handleLeft.rotation.z = Math.PI / 2;
    trophyGroup.add(handleLeft);

    const handleRight = new THREE.Mesh(handleGeo, goldMat);
    handleRight.position.set(0.7, 0.3, 0);
    handleRight.rotation.z = -Math.PI / 2;
    trophyGroup.add(handleRight);

    scene.add(trophyGroup);

    // Dynamic Lighting
    const ambientLight = new THREE.AmbientLight(0xffffff, 1.2);
    scene.add(ambientLight);

    const light1 = new THREE.PointLight(0xFFD700, 3, 10);
    light1.position.set(3, 4, 3);
    scene.add(light1);

    const light2 = new THREE.PointLight(0x00F0FF, 2, 10);
    light2.position.set(-3, -2, -3);
    scene.add(light2);

    let animId;
    const animate = () => {
      animId = requestAnimationFrame(animate);

      trophyGroup.rotation.y += 0.015;
      trophyGroup.position.y = Math.sin(Date.now() * 0.002) * 0.08;

      renderer.render(scene, camera);
    };

    animate();

    return () => {
      cancelAnimationFrame(animId);
      if (mountNode && renderer.domElement) {
        mountNode.removeChild(renderer.domElement);
      }
      renderer.dispose();
    };
  }, [width, height]);

  return <div ref={mountRef} className="flex items-center justify-center pointer-events-none" />;
}
