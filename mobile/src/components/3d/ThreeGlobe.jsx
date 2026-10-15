import React, { useEffect, useRef } from 'react';
import * as THREE from 'three';

export default function ThreeGlobe({ width = 260, height = 260 }) {
  const mountRef = useRef(null);

  useEffect(() => {
    const mountNode = mountRef.current;
    if (!mountNode) return;

    // Scene, Camera, Renderer
    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(45, width / height, 0.1, 1000);
    camera.position.z = 4.5;

    const renderer = new THREE.WebGLRenderer({ alpha: true, antialias: true });
    renderer.setSize(width, height);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    mountNode.appendChild(renderer.domElement);

    // Globe Core Sphere
    const sphereGeo = new THREE.SphereGeometry(1.5, 36, 36);
    const sphereMat = new THREE.MeshPhongMaterial({
      color: 0x0B1428,
      emissive: 0x030A19,
      specular: 0x00F0FF,
      shininess: 40,
      transparent: true,
      opacity: 0.95
    });
    const globe = new THREE.Mesh(sphereGeo, sphereMat);
    scene.add(globe);

    // Wireframe Grid Overlay
    const wireGeo = new THREE.SphereGeometry(1.52, 24, 24);
    const wireMat = new THREE.MeshBasicMaterial({
      color: 0x00F0FF,
      wireframe: true,
      transparent: true,
      opacity: 0.25
    });
    const wireframe = new THREE.Mesh(wireGeo, wireMat);
    scene.add(wireframe);

    // Atmosphere Glow Outer Shell
    const atmoGeo = new THREE.SphereGeometry(1.65, 32, 32);
    const atmoMat = new THREE.MeshBasicMaterial({
      color: 0x00F0FF,
      transparent: true,
      opacity: 0.12,
      side: THREE.BackSide
    });
    const atmosphere = new THREE.Mesh(atmoGeo, atmoMat);
    scene.add(atmosphere);

    // Territory Pins on 3D Globe
    const pinGroup = new THREE.Group();
    const pinGeo = new THREE.SphereGeometry(0.06, 12, 12);
    const pinMatCyan = new THREE.MeshBasicMaterial({ color: 0x00F0FF });
    const pinMatGold = new THREE.MeshBasicMaterial({ color: 0xFFD700 });
    const pinMatRed = new THREE.MeshBasicMaterial({ color: 0xFF0055 });

    // Place random pins on sphere surface
    const pinCoords = [
      { lat: 20, lng: 75, mat: pinMatCyan },
      { lat: 35, lng: -100, mat: pinMatGold },
      { lat: 50, lng: 15, mat: pinMatRed },
      { lat: -25, lng: 135, mat: pinMatCyan },
      { lat: 10, lng: 105, mat: pinMatGold }
    ];

    pinCoords.forEach(({ lat, lng, mat }) => {
      const phi = (90 - lat) * (Math.PI / 180);
      const theta = (lng + 180) * (Math.PI / 180);
      const radius = 1.54;

      const x = -(radius * Math.sin(phi) * Math.cos(theta));
      const z = radius * Math.sin(phi) * Math.sin(theta);
      const y = radius * Math.cos(phi);

      const pin = new THREE.Mesh(pinGeo, mat);
      pin.position.set(x, y, z);
      pinGroup.add(pin);
    });

    scene.add(pinGroup);

    // Lighting
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.8);
    scene.add(ambientLight);

    const dirLight1 = new THREE.DirectionalLight(0x00F0FF, 2.5);
    dirLight1.position.set(5, 3, 5);
    scene.add(dirLight1);

    const dirLight2 = new THREE.DirectionalLight(0xB026FF, 1.8);
    dirLight2.position.set(-5, -3, -5);
    scene.add(dirLight2);

    // Animation Loop
    let animId;
    const animate = () => {
      animId = requestAnimationFrame(animate);

      globe.rotation.y += 0.005;
      wireframe.rotation.y += 0.005;
      wireframe.rotation.x += 0.001;
      pinGroup.rotation.y += 0.005;

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
