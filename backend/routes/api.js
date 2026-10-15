/**
 * CONQUER — Express REST API Router
 * Geospatial Engine, Territory Ownership, Events, Notifications & Gamification
 */

const express = require('express');
const router = express.Router();
const { validatePolygon, claimTerritory, calculateRouteDistance } = require('../services/territoryEngine');
const { evaluateActivityTrust } = require('../services/antiCheatService');
const { calculateActivityRewards, getLevelInfo, updateDailyStreak } = require('../services/xpService');
const { createNotification, sendTerritoryAttackAlert, getUserNotifications } = require('../services/notificationService');

// In-Memory state fallback when MongoDB is not connected
const memoryStore = {
  users: [
    {
      id: 'u_shravan',
      username: 'SHRAVAN',
      email: 'shravan@conquer.app',
      avatar: '⚔️',
      level: 14,
      xp: 19600,
      coins: 1450,
      totalSteps: 1240500,
      totalDistanceKm: 642.5,
      totalTerritoryKm2: 24.82,
      streakDays: 28,
      playerColor: '#3B82F6', // Blue
      role: 'admin',
      achievements: ['first_recon', 'first_conquest', 'distance_1km']
    },
    {
      id: 'u_rahul',
      username: 'RAHUL',
      email: 'rahul@conquer.app',
      avatar: '🛡️',
      level: 11,
      xp: 12100,
      coins: 890,
      totalSteps: 842100,
      totalDistanceKm: 412.0,
      totalTerritoryKm2: 14.50,
      streakDays: 14,
      playerColor: '#EF4444', // Red
      role: 'player',
      achievements: ['first_recon', 'first_conquest']
    },
    {
      id: 'u_priya',
      username: 'PRIYA_RUNNER',
      email: 'priya@conquer.app',
      avatar: '🏃‍♀️',
      level: 9,
      xp: 8100,
      coins: 620,
      totalSteps: 620400,
      totalDistanceKm: 310.8,
      totalTerritoryKm2: 8.90,
      streakDays: 7,
      playerColor: '#10B981', // Green
      role: 'player',
      achievements: ['first_recon']
    }
  ],
  territories: [
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
      },
      createdAt: new Date(Date.now() - 86400000 * 2)
    },
    {
      id: 't_rahul_1',
      ownerId: 'u_rahul',
      ownerName: 'RAHUL',
      color: '#EF4444',
      areaKm2: 0.95,
      status: 'active',
      geometry: {
        type: 'Polygon',
        coordinates: [[
          [74.750, 13.342],
          [74.756, 13.342],
          [74.756, 13.349],
          [74.750, 13.349],
          [74.750, 13.342]
        ]]
      },
      createdAt: new Date(Date.now() - 86400000 * 1)
    }
  ],
  territoryEvents: [
    {
      id: 'evt_initial_1',
      type: 'conquest',
      actorId: 'u_shravan',
      actorName: 'SHRAVAN',
      areaKm2: 1.82,
      stolenAreaKm2: 0,
      territoryId: 't_shravan_1',
      message: 'SHRAVAN conquered Waterfront Enclave (1.82 km²).',
      timestamp: new Date(Date.now() - 86400000 * 2)
    },
    {
      id: 'evt_initial_2',
      type: 'conquest',
      actorId: 'u_rahul',
      actorName: 'RAHUL',
      areaKm2: 0.95,
      stolenAreaKm2: 0,
      territoryId: 't_rahul_1',
      message: 'RAHUL founded Cyber Citadel (0.95 km²).',
      timestamp: new Date(Date.now() - 86400000 * 1)
    }
  ],
  allAchievements: [
    { id: 'first_recon', title: 'First Recon', desc: 'Complete your first physical GPS recon activity', icon: 'explore' },
    { id: 'first_conquest', title: 'Empire Founded', desc: 'Complete a closed GPS loop and conquer territory', icon: 'flag' },
    { id: 'rival_slice', title: 'Territory Hunter', desc: 'Capture overlapping territory from a rival player', icon: 'gps_fixed' },
    { id: 'distance_1km', title: 'Centurion Scout', desc: 'Travel over 1 km in reconnaissance', icon: 'directions_walk' },
    { id: 'area_1km2', title: 'Domain Lord', desc: 'Accumulate over 1 km² of total territory', icon: 'shield' },
    { id: 'streak_7', title: 'Relentless Vanguard', desc: 'Maintain a 7-day recon streak', icon: 'local_fire_department' }
  ],
  activities: [],
  conquests: [],
  gameSettings: {
    minLoopDistanceMeters: 100,
    returnToleranceMeters: 10,
    dailyStepGoal: 2000,
    xpPerKm: 50,
    coinsPerConquest: 30,
    maxRunningSpeedKmH: 20
  }
};

/**
 * Evaluates and awards basic achievements based on progress.
 */
function evaluateAchievements(user, claimResult, distanceKm) {
  const unlocked = [];
  user.achievements = user.achievements || [];

  // 1. First Recon
  if (!user.achievements.includes('first_recon')) {
    user.achievements.push('first_recon');
    unlocked.push(memoryStore.allAchievements.find(a => a.id === 'first_recon'));
  }

  // 2. Empire Founded
  if (claimResult.territoryAwarded && !user.achievements.includes('first_conquest')) {
    user.achievements.push('first_conquest');
    unlocked.push(memoryStore.allAchievements.find(a => a.id === 'first_conquest'));
  }

  // 3. Rival Slice (Stole enemy land)
  if (claimResult.territoryAwarded && (claimResult.captureDetails?.stolenFromEnemiesKm2 || 0) > 0) {
    if (!user.achievements.includes('rival_slice')) {
      user.achievements.push('rival_slice');
      unlocked.push(memoryStore.allAchievements.find(a => a.id === 'rival_slice'));
    }
  }

  // 4. Centurion Scout
  if (user.totalDistanceKm >= 1.0 && !user.achievements.includes('distance_1km')) {
    user.achievements.push('distance_1km');
    unlocked.push(memoryStore.allAchievements.find(a => a.id === 'distance_1km'));
  }

  // 5. Domain Lord
  if (user.totalTerritoryKm2 >= 1.0 && !user.achievements.includes('area_1km2')) {
    user.achievements.push('area_1km2');
    unlocked.push(memoryStore.allAchievements.find(a => a.id === 'area_1km2'));
  }

  return unlocked.filter(Boolean);
}

// --- AUTH & USER PROFILE ENDPOINTS ---
router.post('/auth/login', (req, res) => {
  const { username } = req.body;
  const user = memoryStore.users.find(u => u.username.toLowerCase() === (username || '').toLowerCase()) || memoryStore.users[0];
  return res.json({
    token: 'jwt_mock_token_' + user.id,
    user
  });
});

router.post('/auth/switch', (req, res) => {
  const { userId } = req.body;
  const user = memoryStore.users.find(u => u.id === userId) || memoryStore.users[0];
  return res.json({
    success: true,
    message: `Active account switched to ${user.username}`,
    user
  });
});

router.get('/auth/me', (req, res) => {
  const userId = req.query.userId || req.headers['x-user-id'] || 'u_shravan';
  const user = memoryStore.users.find(u => u.id === userId) || memoryStore.users[0];
  return res.json({ user });
});

router.get('/users/profile/:id', (req, res) => {
  const user = memoryStore.users.find(u => u.id === req.params.id);
  if (!user) return res.status(404).json({ error: 'User not found' });
  return res.json({ user });
});

// --- GAME & LOOP VALIDATION ENDPOINTS ---

/**
 * POST /api/activities/validate-loop
 * Evaluates live GPS path for loop completion without submitting final activity.
 */
router.post('/activities/validate-loop', (req, res) => {
  const { points } = req.body;
  const config = memoryStore.gameSettings;

  const result = validatePolygon(points, {
    minDistanceMeters: config.minLoopDistanceMeters,
    returnToleranceMeters: config.returnToleranceMeters
  });

  return res.json({
    isValid: result.isValid,
    reason: result.reason,
    pathDistance: result.pathDistanceMeters,
    returnDistance: result.returnDistanceMeters,
    areaKm2: result.areaKm2,
    areaMeters: result.areaMeters,
    polygon: result.polygon
  });
});

/**
 * POST /api/activities/submit
 * Submits a completed conquest activity, runs anti-cheat, loop detection, and territory capture.
 */
router.post('/activities/submit', async (req, res) => {
  const { userId, points, steps, durationSeconds, activityType } = req.body;

  const user = memoryStore.users.find(u => u.id === userId) || memoryStore.users[0];
  const trust = evaluateActivityTrust(points);
  const routeDistMeters = calculateRouteDistance(points);
  const distanceKm = routeDistMeters / 1000.0;

  // Execute concurrency-safe territory engine claim
  const claimResult = await claimTerritory({
    userId: user.id,
    username: user.username,
    userColor: user.playerColor,
    points,
    steps,
    durationSeconds,
    activityType,
    storage: memoryStore
  });

  // Calculate XP & Coin Rewards
  const conqueredAreaKm2 = claimResult.territoryAwarded
    ? (claimResult.captureDetails?.newLoopAreaKm2 || 0)
    : 0;
  const stolenEnemyAreaKm2 = claimResult.territoryAwarded
    ? (claimResult.captureDetails?.stolenFromEnemiesKm2 || 0)
    : 0;

  const rewards = calculateActivityRewards({
    distanceKm,
    steps: steps || Math.round(distanceKm * 1350),
    loopCompleted: claimResult.territoryAwarded,
    areaConqueredKm2: conqueredAreaKm2,
    capturedEnemyAreaKm2: stolenEnemyAreaKm2
  });

  // Update User Progression Stats
  user.xp += rewards.xp;
  user.coins += rewards.coins;
  user.totalSteps += (steps || Math.round(distanceKm * 1350));
  user.totalDistanceKm += distanceKm;

  // Handle Territory Events & Notifications
  if (claimResult.territoryAwarded) {
    user.totalTerritoryKm2 += conqueredAreaKm2;

    // 1. Create Territory History Event
    const event = {
      id: 'evt_' + Date.now(),
      type: stolenEnemyAreaKm2 > 0 ? 'capture' : 'conquest',
      actorId: user.id,
      actorName: user.username,
      areaKm2: conqueredAreaKm2,
      stolenAreaKm2: stolenEnemyAreaKm2,
      territoryId: claimResult.captureDetails?.attackerTerritory?.id,
      message: stolenEnemyAreaKm2 > 0
        ? `${user.username} sliced & captured ${stolenEnemyAreaKm2.toFixed(2)} km² from rival territory!`
        : `${user.username} enclosed and founded ${conqueredAreaKm2.toFixed(2)} km² of territory!`,
      timestamp: new Date()
    };
    memoryStore.territoryEvents.unshift(event);

    // 2. Notification for Attacker
    createNotification({
      userId: user.id,
      type: 'conquest',
      title: '🏆 TERRITORY CONQUERED',
      message: stolenEnemyAreaKm2 > 0
        ? `Victory! You captured ${stolenEnemyAreaKm2.toFixed(2)} km² from enemy territory!`
        : `Victory! You expanded your empire by +${conqueredAreaKm2.toFixed(2)} km²!`,
      relatedTerritoryId: claimResult.captureDetails?.attackerTerritory?.id
    });

    // 3. Notifications for Affected Defenders
    if (claimResult.captureDetails?.affectedDefenders) {
      for (const defender of claimResult.captureDetails.affectedDefenders) {
        const defUser = memoryStore.users.find(u => u.id.toString() === defender.defenderId.toString());
        if (defUser) {
          defUser.totalTerritoryKm2 = Math.max(0, defUser.totalTerritoryKm2 - defender.lostAreaKm2);
          sendTerritoryAttackAlert(defender.defenderId, user.username, defender.lostAreaKm2, defender.territoryId);
        }
      }
    }
  }

  // Evaluate & Unlock Achievements
  const unlockedAchievements = evaluateAchievements(user, claimResult, distanceKm);
  for (const ach of unlockedAchievements) {
    createNotification({
      userId: user.id,
      type: 'achievement',
      title: '🏅 ACHIEVEMENT UNLOCKED',
      message: `Unlocked "${ach.title}": ${ach.desc}`
    });
  }

  // Update level
  const levelData = getLevelInfo(user.xp);
  user.level = levelData.level;

  const activityRecord = {
    id: 'act_' + Date.now(),
    userId: user.id,
    type: activityType || trust.inferredActivityType || 'walking',
    distanceKm: Math.round(distanceKm * 100) / 100,
    durationSeconds: durationSeconds || Math.round(distanceKm * 720),
    steps: steps || Math.round(distanceKm * 1350),
    loopCompleted: claimResult.territoryAwarded,
    areaConqueredKm2: Math.round(conqueredAreaKm2 * 100) / 100,
    capturedAreaKm2: Math.round(stolenEnemyAreaKm2 * 100) / 100,
    trustScore: trust.trustScore,
    validationStatus: trust.validationStatus,
    xpEarned: rewards.xp,
    coinsEarned: rewards.coins,
    createdAt: new Date()
  };

  memoryStore.activities.unshift(activityRecord);

  return res.json({
    success: true,
    activity: activityRecord,
    loopResult: {
      isValid: claimResult.territoryAwarded,
      reason: claimResult.reason || 'Conquest validated and territory claimed successfully.',
      pathDistance: routeDistMeters,
      returnDistance: claimResult.loopDetails?.returnDistanceMeters
    },
    territoryAwarded: claimResult.territoryAwarded,
    conquest: claimResult.captureDetails,
    unlockedAchievements,
    rewards,
    user
  });
});

// --- TERRITORY & EVENT ENDPOINTS ---
router.get('/territories/nearby', (req, res) => {
  return res.json({ territories: memoryStore.territories });
});

router.get('/territories/mine', (req, res) => {
  const userId = req.query.userId || req.headers['x-user-id'] || 'u_shravan';
  const mine = memoryStore.territories.filter(t => t.ownerId.toString() === userId.toString() && t.status === 'active');
  return res.json({ territories: mine });
});

router.get('/territories/events', (req, res) => {
  return res.json({ events: memoryStore.territoryEvents });
});

// --- NOTIFICATIONS & ACHIEVEMENTS ENDPOINTS ---
router.get('/notifications', (req, res) => {
  const userId = req.query.userId || req.headers['x-user-id'] || 'u_shravan';
  const notifs = getUserNotifications(userId);
  return res.json({ notifications: notifs });
});

router.post('/notifications/:id/read', (req, res) => {
  const notif = getUserNotifications(req.query.userId || 'u_shravan').find(n => n.id === req.params.id);
  if (notif) notif.read = true;
  return res.json({ success: true });
});

router.get('/achievements', (req, res) => {
  const userId = req.query.userId || req.headers['x-user-id'] || 'u_shravan';
  const user = memoryStore.users.find(u => u.id === userId) || memoryStore.users[0];
  const userAchievements = user.achievements || [];

  const achievementsWithStatus = memoryStore.allAchievements.map(ach => ({
    ...ach,
    unlocked: userAchievements.includes(ach.id)
  }));

  return res.json({ achievements: achievementsWithStatus });
});

// --- LEADERBOARD ENDPOINTS ---
router.get('/leaderboard/global', (req, res) => {
  const sorted = [...memoryStore.users].sort((a, b) => b.totalTerritoryKm2 - a.totalTerritoryKm2);
  return res.json({ leaderboard: sorted });
});

// --- ADMIN ENDPOINTS ---
router.get('/admin/stats', (req, res) => {
  const totalArea = memoryStore.territories.reduce((acc, t) => acc + (t.areaKm2 || 0), 0);
  return res.json({
    totalUsers: memoryStore.users.length,
    activeToday: Math.round(memoryStore.users.length * 0.8),
    totalConquests: memoryStore.conquests.length + 37,
    totalTerritoryKm2: Math.round(totalArea * 100) / 100,
    settings: memoryStore.gameSettings
  });
});

module.exports = router;
