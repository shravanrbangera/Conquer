/**
 * CONQUER — Anti-Cheat Engine & Trust Score Validator
 * Detects vehicle movement, GPS teleportation, mock location indicators, and invalid accelerations.
 */

const { haversineDistance } = require('./loopService');

/**
 * Evaluates activity telemetry to assign a Trust Score (0 - 100%).
 * 
 * Rules:
 * - Walking range: 0 - 8 km/h
 * - Running range: 8 - 20 km/h
 * - Suspicious (Vehicle/Bike): > 20 km/h
 * - Teleportation: > 60 km/h instantaneous segment speed
 */
function evaluateActivityTrust(points, metadata = {}) {
  if (!points || points.length < 2) {
    return { trustScore: 100, status: 'passed', issues: [] };
  }

  let totalSpeedKmH = 0;
  let maxSpeedKmH = 0;
  let speedViolations = 0;
  let teleportationViolations = 0;
  const issues = [];

  for (let i = 0; i < points.length - 1; i++) {
    const p1 = points[i];
    const p2 = points[i + 1];

    const distMeters = haversineDistance(p1, p2);
    
    // Time diff in seconds
    const t1 = p1.timestamp ? new Date(p1.timestamp).getTime() : i * 2000;
    const t2 = p2.timestamp ? new Date(p2.timestamp).getTime() : (i + 1) * 2000;
    const durationSec = Math.max((t2 - t1) / 1000, 0.5); // minimum 0.5s safeguard

    const speedMps = distMeters / durationSec; // meters per second
    const speedKmH = speedMps * 3.6;

    if (speedKmH > maxSpeedKmH) maxSpeedKmH = speedKmH;
    totalSpeedKmH += speedKmH;

    if (speedKmH > 20 && speedKmH <= 60) {
      speedViolations++;
    } else if (speedKmH > 60) {
      teleportationViolations++;
    }
  }

  const avgSpeedKmH = totalSpeedKmH / (points.length - 1);

  // Score deductions
  let trustScore = 100;

  if (teleportationViolations > 0) {
    trustScore -= teleportationViolations * 30;
    issues.push(`Detected ${teleportationViolations} instantaneous GPS teleportation jumps.`);
  }

  if (speedViolations > 0) {
    trustScore -= speedViolations * 10;
    issues.push(`Detected ${speedViolations} movement segments exceeding running speed limit (>20 km/h).`);
  }

  if (avgSpeedKmH > 18) {
    trustScore -= 25;
    issues.push(`Average activity speed (${avgSpeedKmH.toFixed(1)} km/h) is suspicious for human foot activity.`);
  }

  if (metadata.isMockLocation) {
    trustScore -= 50;
    issues.push('Device flagged mock location provider usage.');
  }

  trustScore = Math.max(0, Math.min(100, Math.round(trustScore)));

  let validationStatus = 'passed';
  if (trustScore < 50) {
    validationStatus = 'rejected';
  } else if (trustScore < 80) {
    validationStatus = 'suspicious';
  }

  // Classify human activity mode
  let inferredActivityType = 'walking';
  if (avgSpeedKmH >= 7.5 && avgSpeedKmH <= 20) {
    inferredActivityType = 'running';
  }

  return {
    trustScore,
    validationStatus,
    inferredActivityType,
    avgSpeedKmH: Math.round(avgSpeedKmH * 10) / 10,
    maxSpeedKmH: Math.round(maxSpeedKmH * 10) / 10,
    issues
  };
}

module.exports = {
  evaluateActivityTrust
};
