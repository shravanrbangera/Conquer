/**
 * CONQUER — XP, Leveling & Gamification Engine
 */

const LEVEL_TITLES = [
  'Newcomer',        // L1
  'Walker',          // L2
  'Explorer',        // L3
  'Conqueror',       // L4
  'Warrior',         // L5
  'Territory Hunter',// L6
  'Land Master',     // L7
  'Champion',        // L8
  'Legend',          // L9
  'WORLD CONQUEROR'  // L10
];

/**
 * Calculates XP and Coins awarded for a completed activity session.
 */
function calculateActivityRewards({ distanceKm = 0, steps = 0, loopCompleted = false, areaConqueredKm2 = 0, capturedEnemyAreaKm2 = 0 }) {
  // Base rewards
  let xp = Math.round(distanceKm * 50); // 50 XP per km
  xp += Math.round(steps / 100);       // 1 XP per 100 steps
  let coins = Math.round(distanceKm * 10); // 10 coins per km

  // Conquest bonuses
  if (loopCompleted && areaConqueredKm2 > 0) {
    xp += 150; // Bonus for successful loop
    xp += Math.round(areaConqueredKm2 * 200); // 200 XP per km² owned
    coins += 30; // Base conquest coins
    coins += Math.round(areaConqueredKm2 * 50);
  }

  // Enemy territory capture extra bonus
  if (capturedEnemyAreaKm2 > 0) {
    xp += Math.round(capturedEnemyAreaKm2 * 400); // Heavy reward for taking land
    coins += Math.round(capturedEnemyAreaKm2 * 100);
  }

  return {
    xp: Math.max(10, xp),
    coins: Math.max(5, coins)
  };
}

/**
 * Calculates level from total XP.
 * Formula: Level = Math.floor(sqrt(XP / 100)) + 1
 */
function getLevelInfo(totalXp = 0) {
  let level = Math.floor(Math.sqrt(totalXp / 100)) + 1;
  level = Math.min(10, Math.max(1, level));

  const currentLevelMinXp = (level - 1) * (level - 1) * 100;
  const nextLevelXp = level * level * 100;
  
  const xpInCurrentLevel = totalXp - currentLevelMinXp;
  const xpRequiredForNext = nextLevelXp - currentLevelMinXp;
  const progressPercent = Math.min(100, Math.round((xpInCurrentLevel / xpRequiredForNext) * 100));

  return {
    level,
    title: LEVEL_TITLES[level - 1] || 'WORLD CONQUEROR',
    totalXp,
    xpInCurrentLevel,
    xpRequiredForNext,
    progressPercent,
    isMaxLevel: level >= 10
  };
}

/**
 * Evaluates daily streak.
 */
function updateDailyStreak(lastActiveDate, currentStreak = 0, currentDailySteps = 0) {
  const now = new Date();
  const todayStr = now.toISOString().split('T')[0];

  if (!lastActiveDate) {
    return { streak: 1, lastActiveDate: now };
  }

  const lastStr = new Date(lastActiveDate).toISOString().split('T')[0];
  const diffDays = Math.round((new Date(todayStr) - new Date(lastStr)) / (1000 * 3600 * 24));

  if (diffDays === 0) {
    return { streak: currentStreak, lastActiveDate: now };
  } else if (diffDays === 1) {
    return { streak: currentStreak + 1, lastActiveDate: now };
  } else {
    // Reset streak if missed more than 1 day
    return { streak: 1, lastActiveDate: now };
  }
}

module.exports = {
  calculateActivityRewards,
  getLevelInfo,
  updateDailyStreak,
  LEVEL_TITLES
};
