import React, { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Polyline, Polygon, Marker, Popup, useMap } from 'react-leaflet';
import L from 'leaflet';
import { Layers, Signal, Waves, Compass } from 'lucide-react';
import UnderwaterScene from './3d/UnderwaterScene';

const MAP_THEMES = {
  underwater: {
    name: '🌊 Underwater WebGL 3D',
    url: '',
    className: ''
  },
  cyber: {
    name: 'Cyber Dark',
    url: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
    className: 'carto-dark'
  },
  satellite: {
    name: 'Satellite Hybrid',
    url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    className: 'carto-satellite'
  }
};

const createCyberPin = (color = '#00F0FF', icon = '⚔️') => {
  return L.divIcon({
    className: 'custom-cyber-pin',
    html: `
      <div style="position: relative; width: 48px; height: 48px; display: flex; align-items: center; justify-content: center;">
        <div style="
          position: absolute;
          inset: -4px;
          border-radius: 50%;
          background: ${color};
          opacity: 0.45;
          filter: blur(10px);
        "></div>
        <div style="
          position: relative;
          width: 40px;
          height: 40px;
          border-radius: 50%;
          background: linear-gradient(135deg, #10172A, #040711);
          border: 2px solid ${color};
          box-shadow: 0 0 20px ${color}, inset 0 0 12px ${color}88;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 20px;
        ">
          ${icon}
        </div>
      </div>
    `,
    iconSize: [48, 48],
    iconAnchor: [24, 24]
  });
};

const startPinIcon = L.divIcon({
  className: 'start-pin-icon',
  html: `
    <div style="
      background: linear-gradient(135deg, #00FF9D, #00B36B);
      color: #040711;
      padding: 5px 12px;
      border-radius: 16px;
      font-family: 'Outfit', sans-serif;
      font-weight: 900;
      font-size: 11px;
      letter-spacing: 0.8px;
      border: 2px solid #ffffff;
      box-shadow: 0 0 20px #00FF9D;
      display: flex;
      align-items: center;
      gap: 5px;
    ">
      <span>🏁</span> START LOOP
    </div>
  `,
  iconSize: [90, 28],
  iconAnchor: [45, 14]
});

function MapRecenter({ center }) {
  const map = useMap();
  useEffect(() => {
    if (center) {
      map.setView(center, map.getZoom(), { animate: true });
    }
  }, [center, map]);
  return null;
}

export default function MapView({
  userLocation,
  routePoints = [],
  territories = [],
  activeConquest = false,
  loopCompleted = false,
  previewPolygon = null
}) {
  const [currentThemeKey, setCurrentThemeKey] = useState('underwater');
  const [showThemePicker, setShowThemePicker] = useState(false);
  const [depthLevel, setDepthLevel] = useState(0); // 0: Surface, 1: Abyss, 2: Deep Seafloor

  const activeTheme = MAP_THEMES[currentThemeKey];
  const mapCenter = userLocation ? [userLocation.lat, userLocation.lng] : [13.344, 74.744];
  const polylineCoords = routePoints.map(p => [p.lat, p.lng]);

  return (
    <div className={`relative w-full h-full ${activeTheme.className}`}>
      {/* 3D WebGL Underwater Scene */}
      {currentThemeKey === 'underwater' && (
        <UnderwaterScene depthLevel={depthLevel} />
      )}

      {/* Top Map Bar: Underwater Depth Scrollyteller Controls & Theme Switcher */}
      <div className="absolute top-4 right-4 z-20 flex items-center gap-2">
        {currentThemeKey === 'underwater' && (
          <div className="cyber-glass px-3 py-1.5 rounded-full flex items-center gap-2 border border-cyan-500/30 text-[11px] font-extrabold text-cyan-300">
            <Waves className="w-3.5 h-3.5 text-cyan-400 animate-pulse" />
            <span>DEPTH: {depthLevel === 0 ? 'SURFACE (50m)' : depthLevel === 1 ? 'ABYSS (300m)' : 'SEAFLOOR (800m)'}</span>
          </div>
        )}

        <button
          onClick={() => setShowThemePicker(!showThemePicker)}
          className="cyber-glass p-2.5 rounded-full text-cyan-400 hover:text-white border border-cyan-500/30 transition shadow-lg glow-cyan"
          title="Switch Environment Theme"
        >
          <Layers className="w-4.5 h-4.5" />
        </button>

        {showThemePicker && (
          <div className="absolute top-12 right-0 cyber-glass rounded-2xl p-2 flex flex-col gap-1 border border-cyan-500/40 w-44 shadow-2xl z-30">
            {Object.keys(MAP_THEMES).map((key) => (
              <button
                key={key}
                onClick={() => {
                  setCurrentThemeKey(key);
                  setShowThemePicker(false);
                }}
                className={`py-2 px-3 rounded-xl text-xs font-bold text-left transition ${
                  currentThemeKey === key ? 'bg-cyan-500/30 text-cyan-300 border border-cyan-400/50' : 'text-gray-300 hover:bg-gray-800/60'
                }`}
              >
                {MAP_THEMES[key].name}
              </button>
            ))}
          </div>
        )}
      </div>

      {/* Depth Scrollyteller Quick Switcher Pill (Underwater Mode Only) */}
      {currentThemeKey === 'underwater' && (
        <div className="absolute top-16 left-4 z-20 flex items-center gap-1 cyber-glass rounded-2xl p-1 border border-cyan-500/30">
          <button
            onClick={() => setDepthLevel(0)}
            className={`px-2.5 py-1 rounded-xl text-[10px] font-mono font-bold transition ${
              depthLevel === 0 ? 'bg-cyan-500 text-black' : 'text-gray-400 hover:text-white'
            }`}
          >
            Surface
          </button>
          <button
            onClick={() => setDepthLevel(1)}
            className={`px-2.5 py-1 rounded-xl text-[10px] font-mono font-bold transition ${
              depthLevel === 1 ? 'bg-cyan-500 text-black' : 'text-gray-400 hover:text-white'
            }`}
          >
            Abyss
          </button>
          <button
            onClick={() => setDepthLevel(2)}
            className={`px-2.5 py-1 rounded-xl text-[10px] font-mono font-bold transition ${
              depthLevel === 2 ? 'bg-cyan-500 text-black' : 'text-gray-400 hover:text-white'
            }`}
          >
            Seafloor
          </button>
        </div>
      )}

      {/* 2D Map Overlay Layer (Leaflet Map when not underwater, or floating map overlay) */}
      {currentThemeKey !== 'underwater' && (
        <MapContainer
          center={mapCenter}
          zoom={16}
          zoomControl={false}
          className="w-full h-full z-0"
        >
          <TileLayer attribution='&copy; CARTO' url={activeTheme.url} />
          <MapRecenter center={mapCenter} />

          {territories.map((t, idx) => {
            if (!t.geometry || !t.geometry.coordinates) return null;
            const leafletCoords = t.geometry.coordinates[0].map(c => [c[1], c[0]]);
            const territoryColor = t.color || '#3B82F6';

            return (
              <Polygon
                key={t.id || idx}
                positions={leafletCoords}
                pathOptions={{
                  color: territoryColor,
                  fillColor: territoryColor,
                  fillOpacity: 0.48,
                  weight: 3,
                  dashArray: '8, 6'
                }}
              />
            );
          })}

          {polylineCoords.length > 1 && (
            <Polyline
              positions={polylineCoords}
              pathOptions={{
                color: loopCompleted ? '#00FF9D' : '#00F0FF',
                weight: 6,
                opacity: 0.95
              }}
            />
          )}

          {activeConquest && routePoints.length > 0 && (
            <Marker position={[routePoints[0].lat, routePoints[0].lng]} icon={startPinIcon} />
          )}

          {userLocation && (
            <Marker
              position={[userLocation.lat, userLocation.lng]}
              icon={createCyberPin(activeConquest ? '#00F0FF' : '#3B82F6', activeConquest ? '⚔️' : '🚶')}
            />
          )}
        </MapContainer>
      )}
    </div>
  );
}
