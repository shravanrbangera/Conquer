import React, { useState, useEffect, useRef } from 'react';
import MapView from './components/MapView';
import ConquestHUD from './components/ConquestHUD';
import VictoryModal from './components/VictoryModal';
import DualPlayerSimulator from './components/DualPlayerSimulator';
import OnboardingModal from './components/OnboardingModal';
import LeaderboardScreen from './screens/LeaderboardScreen';
import ProfileScreen from './screens/ProfileScreen';
import FriendsScreen from './screens/FriendsScreen';
import AdminScreen from './screens/AdminScreen';

import { Map, Trophy, Users, User, Sliders, Play, Footprints } from 'lucide-react';
import { checkLoopValidity, createClosedPolygon } from './services/loopService';
import { processTerritoryCapture } from './services/polygonService';

const INITIAL_USERS = [
  {
    id: 'u_shravan',
    username: 'SHRAVAN',
    level: 14,
    xp: 19600,
    coins: 1450,
    totalSteps: 1240500,
    totalDistanceKm: 642.5,
    totalTerritoryKm2: 24.82,
    streakDays: 28,
    playerColor: '#3B82F6',
    avatar: '⚔️'
  },
  {
    id: 'u_rahul',
    username: 'RAHUL',
    level: 11,
    xp: 12100,
    coins: 890,
    totalSteps: 842100,
    totalDistanceKm: 412.0,
    totalTerritoryKm2: 14.50,
    streakDays: 14,
    playerColor: '#FF0055',
    avatar: '🛡️'
  },
  {
    id: 'u_priya',
    username: 'PRIYA_RUNNER',
    level: 9,
    xp: 8100,
    coins: 620,
    totalSteps: 620400,
    totalDistanceKm: 310.8,
    totalTerritoryKm2: 8.90,
    streakDays: 7,
    playerColor: '#00FF9D',
    avatar: '🏃‍♀️'
  }
];

export default function App() {
  const [activeTab, setActiveTab] = useState('map');
  const [showOnboarding, setShowOnboarding] = useState(true);

  const [users, setUsers] = useState(INITIAL_USERS);
  const currentUser = users[0];

  const [territories, setTerritories] = useState([
    {
      id: 't_shravan_1',
      ownerId: 'u_shravan',
      ownerName: 'SHRAVAN',
      color: '#3B82F6',
      areaKm2: 1.82,
      status: 'active',
      geometry: {
        type: 'Polygon',
        coordinates: [[
          [74.740, 13.340],
          [74.748, 13.340],
          [74.748, 13.348],
          [74.740, 13.348],
          [74.740, 13.340]
        ]]
      }
    }
  ]);

  const [activeConquest, setActiveConquest] = useState(false);
  const [isPaused, setIsPaused] = useState(false);
  const [elapsedSeconds, setElapsedSeconds] = useState(0);
  const [userLocation, setUserLocation] = useState({ lat: 13.344, lng: 74.744 });
  const [routePoints, setRoutePoints] = useState([]);
  const [loopStatus, setLoopStatus] = useState({ isValid: false });
  const [previewPolygon, setPreviewPolygon] = useState(null);

  const [victoryData, setVictoryData] = useState(null);
  const [attackAlert, setAttackAlert] = useState(null);

  const timerRef = useRef(null);

  useEffect(() => {
    if (activeConquest && !isPaused) {
      timerRef.current = setInterval(() => {
        setElapsedSeconds(prev => prev + 1);
      }, 1000);
    } else {
      clearInterval(timerRef.current);
    }
    return () => clearInterval(timerRef.current);
  }, [activeConquest, isPaused]);

  useEffect(() => {
    if (activeConquest && routePoints.length >= 4) {
      const result = checkLoopValidity(routePoints, {
        minDistanceMeters: 100,
        returnToleranceMeters: 10
      });
      setLoopStatus(result);

      if (result.isValid) {
        const poly = createClosedPolygon(routePoints);
        setPreviewPolygon(poly);
      } else {
        setPreviewPolygon(null);
      }
    }
  }, [routePoints, activeConquest]);

  const handleStartConquest = () => {
    setActiveConquest(true);
    setIsPaused(false);
    setElapsedSeconds(0);
    const startPt = { lat: 13.340, lng: 74.740 };
    setUserLocation(startPt);
    setRoutePoints([startPt]);
    setLoopStatus({ isValid: false });
    setPreviewPolygon(null);
  };

  const handleSimulateWalkStep = () => {
    if (!activeConquest) {
      handleStartConquest();
      return;
    }

    const waypoints = [
      { lat: 13.340, lng: 74.740 },
      { lat: 13.340, lng: 74.746 },
      { lat: 13.346, lng: 74.746 },
      { lat: 13.346, lng: 74.740 },
      { lat: 13.34001, lng: 74.74001 }
    ];

    const currentLen = routePoints.length;
    if (currentLen < waypoints.length) {
      const nextPt = waypoints[currentLen];
      setUserLocation(nextPt);
      setRoutePoints(prev => [...prev, nextPt]);
    }
  };

  const handleEndConquest = () => {
    if (loopStatus.isValid) {
      const polygon = createClosedPolygon(routePoints);

      const newTerritory = {
        id: 't_' + Date.now(),
        ownerId: currentUser.id,
        ownerName: currentUser.username,
        color: currentUser.playerColor,
        areaKm2: polygon.areaKm2,
        status: 'active',
        geometry: polygon
      };

      setTerritories(prev => [...prev, newTerritory]);

      setUsers(prev => prev.map(u => {
        if (u.id === currentUser.id) {
          return {
            ...u,
            totalTerritoryKm2: u.totalTerritoryKm2 + polygon.areaKm2,
            xp: u.xp + 420,
            coins: u.coins + 85
          };
        }
        return u;
      }));

      setVictoryData({
        areaKm2: polygon.areaKm2,
        distanceKm: (loopStatus.pathDistance || 1800) / 1000,
        steps: Math.round((loopStatus.pathDistance || 1800) * 1.35),
        xp: 420,
        coins: 85
      });
    }

    setActiveConquest(false);
    setRoutePoints([]);
    setPreviewPolygon(null);
  };

  const handleRunShravanLoop = () => {
    handleStartConquest();
    const fullLoop = [
      { lat: 13.340, lng: 74.740 },
      { lat: 13.340, lng: 74.748 },
      { lat: 13.348, lng: 74.748 },
      { lat: 13.348, lng: 74.740 },
      { lat: 13.34001, lng: 74.74001 }
    ];
    setUserLocation(fullLoop[fullLoop.length - 1]);
    setRoutePoints(fullLoop);
  };

  const handleRunRahulAttack = () => {
    const rahulPolygon = {
      type: 'Polygon',
      coordinates: [[
        [74.744, 13.342],
        [74.752, 13.342],
        [74.752, 13.349],
        [74.744, 13.349],
        [74.744, 13.342]
      ]]
    };

    const newRahulTerritory = {
      id: 't_rahul_' + Date.now(),
      ownerId: 'u_rahul',
      ownerName: 'RAHUL',
      color: '#FF0055',
      areaKm2: 0.95,
      status: 'active',
      geometry: rahulPolygon
    };

    setTerritories(prev => [...prev, newRahulTerritory]);

    setAttackAlert({
      title: '🚨 TERRITORY UNDER ATTACK',
      message: 'Rahul completed a loop and captured 0.32 km² of your territory!'
    });
  };

  const handleResetSimulation = () => {
    setTerritories([
      {
        id: 't_shravan_1',
        ownerId: 'u_shravan',
        ownerName: 'SHRAVAN',
        color: '#3B82F6',
        areaKm2: 1.82,
        status: 'active',
        geometry: {
          type: 'Polygon',
          coordinates: [[
            [74.740, 13.340],
            [74.748, 13.340],
            [74.748, 13.348],
            [74.740, 13.348],
            [74.740, 13.340]
          ]]
        }
      }
    ]);
    setAttackAlert(null);
  };

  return (
    <div className="min-h-screen w-full bg-[#030611] flex items-center justify-center p-0 sm:p-4 ambient-bg select-none overflow-hidden">
      
      {/* Centered Smartphone Device Frame Container */}
      <div className="relative w-full max-w-md h-screen sm:h-[880px] sm:max-h-[92vh] bg-navy-950 sm:rounded-[42px] border-0 sm:border-[6px] border-slate-800/80 shadow-[0_25px_80px_rgba(0,0,0,0.85)] flex flex-col overflow-hidden sm:ring-1 sm:ring-white/10">
        
        {/* Onboarding Overlay */}
        {showOnboarding && <OnboardingModal onComplete={() => setShowOnboarding(false)} />}
        
        {/* Victory Conquest Overlay */}
        {victoryData && <VictoryModal conquestData={victoryData} onClose={() => setVictoryData(null)} />}

        {/* Screen Views */}
        <div className="flex-1 relative w-full h-full">
          {activeTab === 'map' && (
            <div className="relative w-full h-full">
              <MapView
                userLocation={userLocation}
                routePoints={routePoints}
                territories={territories}
                activeConquest={activeConquest}
                loopCompleted={loopStatus.isValid}
                previewPolygon={previewPolygon}
              />

              {activeConquest ? (
                <ConquestHUD
                  elapsedSeconds={elapsedSeconds}
                  distanceMeters={loopStatus.pathDistance || 0}
                  steps={Math.round((loopStatus.pathDistance || 0) * 1.35)}
                  speedKmH={4.8}
                  isPaused={isPaused}
                  loopStatus={loopStatus}
                  onPauseToggle={() => setIsPaused(!isPaused)}
                  onEndConquest={handleEndConquest}
                />
              ) : (
                <div className="absolute bottom-20 left-4 right-4 z-10 flex flex-col gap-3">
                  <DualPlayerSimulator
                    onRunShravanLoop={handleRunShravanLoop}
                    onRunRahulAttack={handleRunRahulAttack}
                    onResetSimulation={handleResetSimulation}
                    attackAlert={attackAlert}
                  />

                  <div className="cyber-glass rounded-3xl p-4 border border-cyan-500/30 flex flex-col gap-3 shadow-2xl">
                    <div className="flex items-center justify-between">
                      <div>
                        <div className="text-[10px] text-cyan-400 font-extrabold uppercase tracking-widest">
                          Today's Empire Stats
                        </div>
                        <div className="text-xl font-black text-white font-heading">
                          {(currentUser.totalTerritoryKm2 || 24.82).toFixed(2)} <span className="text-xs text-gray-400 font-normal">km² Owned</span>
                        </div>
                      </div>

                      <div className="flex items-center gap-2 bg-gray-950/80 px-3 py-1.5 rounded-2xl border border-gray-800">
                        <span className="text-sm">🚶</span>
                        <span className="text-xs font-bold text-white">7,842 Steps</span>
                      </div>
                    </div>

                    <div className="grid grid-cols-2 gap-2.5">
                      <button
                        onClick={handleStartConquest}
                        className="py-3.5 px-5 rounded-2xl bg-gradient-to-r from-cyan-500 via-blue-600 to-indigo-600 hover:from-cyan-400 hover:to-indigo-500 text-white font-black text-xs tracking-wider glow-cyan-lg flex items-center justify-center gap-2 transition"
                      >
                        <Play className="w-4 h-4 fill-current" /> START CONQUEST
                      </button>

                      <button
                        onClick={handleSimulateWalkStep}
                        className="py-3.5 px-4 rounded-2xl bg-gradient-to-r from-emerald-500 to-teal-600 hover:from-emerald-400 hover:to-teal-500 text-white font-black text-xs tracking-wider glow-emerald-lg flex items-center justify-center gap-1.5 transition"
                      >
                        <Footprints className="w-4 h-4" /> WALK STEP
                      </button>
                    </div>
                  </div>
                </div>
              )}
            </div>
          )}

          {activeTab === 'rank' && <LeaderboardScreen users={users} />}
          {activeTab === 'profile' && <ProfileScreen user={currentUser} />}
          {activeTab === 'friends' && <FriendsScreen />}
          {activeTab === 'admin' && <AdminScreen />}
        </div>

        {/* Bottom Cyber Navigation Bar */}
        <div className="absolute bottom-0 left-0 right-0 z-30 h-16 cyber-glass border-t border-white/10 flex items-center justify-around px-3 shadow-2xl">
          <button
            onClick={() => setActiveTab('map')}
            className={`flex flex-col items-center gap-1 py-1 px-3 rounded-xl transition ${
              activeTab === 'map' ? 'text-cyan-400 font-black' : 'text-gray-400 hover:text-gray-200'
            }`}
          >
            <Map className="w-5 h-5" />
            <span className="text-[10px] tracking-wider uppercase font-extrabold">Map</span>
          </button>

          <button
            onClick={() => setActiveTab('rank')}
            className={`flex flex-col items-center gap-1 py-1 px-3 rounded-xl transition ${
              activeTab === 'rank' ? 'text-cyan-400 font-black' : 'text-gray-400 hover:text-gray-200'
            }`}
          >
            <Trophy className="w-5 h-5" />
            <span className="text-[10px] tracking-wider uppercase font-extrabold">Rank</span>
          </button>

          <button
            onClick={() => setActiveTab('friends')}
            className={`flex flex-col items-center gap-1 py-1 px-3 rounded-xl transition ${
              activeTab === 'friends' ? 'text-cyan-400 font-black' : 'text-gray-400 hover:text-gray-200'
            }`}
          >
            <Users className="w-5 h-5" />
            <span className="text-[10px] tracking-wider uppercase font-extrabold">Friends</span>
          </button>

          <button
            onClick={() => setActiveTab('profile')}
            className={`flex flex-col items-center gap-1 py-1 px-3 rounded-xl transition ${
              activeTab === 'profile' ? 'text-cyan-400 font-black' : 'text-gray-400 hover:text-gray-200'
            }`}
          >
            <User className="w-5 h-5" />
            <span className="text-[10px] tracking-wider uppercase font-extrabold">Profile</span>
          </button>

          <button
            onClick={() => setActiveTab('admin')}
            className={`flex flex-col items-center gap-1 py-1 px-3 rounded-xl transition ${
              activeTab === 'admin' ? 'text-purple-400 font-black' : 'text-gray-400 hover:text-gray-200'
            }`}
          >
            <Sliders className="w-5 h-5" />
            <span className="text-[10px] tracking-wider uppercase font-extrabold">Admin</span>
          </button>
        </div>

      </div>

    </div>
  );
}
