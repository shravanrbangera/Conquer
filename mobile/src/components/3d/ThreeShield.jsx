import React, { useEffect, useRef } from 'react';
import * as THREE from 'three';

export default function ThreeShield({ width = 180, height = 180, color = 0x00F0FF }) {
  const mountRef = useRef(null);

  useEffect(() => {
    const mountNode = mountRef.current;
    if (!mountNode) return;

    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(45, width / height, 0.1, 1000);
    camera.position.z = 3.5;

    const renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true });
    renderer.setSize(width, height);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    mountNode.appendChild(renderer.domElement);

    const shieldGroup = new THREE.Group();

    // Shield Emblem Geometry (Octahedron scaled)
    const shieldGeo = new THREE.OctahedronGeometry(1, 1);
    const shieldMat = new THREE.MeshStandardMaterial({
      color: color,
      metalness: 0.85,
      roughness: 0.2,
      emissive: color,
      emissiveIntensity: 0.3
    });
    const shield = new THREE.Mesh(shieldGeo, shieldMat);
    shield.scale.set(1, 1.3, 0.3);
    shieldGroup.add(shield);

    // Outer Glowing Ring
    const ringGeo = new THREE.TorusGeometry(1.2, 0.04, 16, 32);
    const ringMat = new THREE.MeshBasicMaterial({ color: color, wireframe: true });
    const ring = new THREE.Mesh(ringGeo, ringMat);
    shieldGroup.add(ring);

    scene.add(shieldGroup);

    // Lights
    const ambientLight = new THREE.AmbientLight(0xffffff, 1);
    scene.add(ambientLight);

    const pLight = new THREE.PointLight(color, 3, 10);
    pLight.position.set(2, 2, 3);
    scene.add(pLight);

    let animId;
    const animate = () => {
      animId = requestAnimationFrame(animate);

      shieldGroup.rotation.y += 0.015;
      ring.rotation.x += 0.01;
      ring.rotation.z += 0.005;

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
  }, [width, height, color]);

  return <div ref={mountRef} className="flex items-center justify-center pointer-events-none" />;
}
