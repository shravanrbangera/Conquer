/**
 * CONQUER — Core Geospatial Territory Engine
 * 
 * Powered by Turf.js for polygon validation, spherical geodesics,
 * area calculations, spatial intersections, geometric differences,
 * and concurrency-safe territory claims.
 * 
 * Gameplay Rules Enforced:
 * 1. Minimum route distance: 100 metres
 * 2. Finish within 10 metres of start point
 * 3. Reject invalid or degenerate polygons (figure-8, self-intersecting, collinear, < 3 points)
 * 4. Validate recorded activity before awarding territory (anti-cheat & plausible human speeds)
 * 5. Capture only overlapping territory (walking through without a loop does not capture)
 * 6. Incomplete loops do not create territory
 * 7. Store territories as GeoJSON (Polygon / MultiPolygon)
 * 8. Support multiple disconnected polygons per player
 * 9. Handle concurrent claims safely
 */

const turf = require('@turf/turf');
const mongoose = require('mongoose');
const { evaluateActivityTrust } = require('./antiCheatService');
const Territory = require('../models/Territory');

const EARTH_RADIUS_METERS = 6371000.0;
const MIN_ROUTE_DISTANCE_METERS = 100.0;
const RETURN_TOLERANCE_METERS = 10.0;
const MIN_POLYGON_AREA_METERS = 1.0; // 1 m² minimum
const MIN_OVERLAP_AREA_KM2 = 0.00001; // 10 m² minimum threshold for territory slice

/**
 * Calculates Haversine distance between two coordinates in meters.
 * Accepts {lat, lng}, {latitude, longitude}, or GeoJSON [lng, lat].
 */
function haversineDistance(p1, p2) {
  if (!p1 || !p2) return 0.0;

  const lat1 = (p1.lat ?? p1.latitude ?? p1[1]) * (Math.PI / 180.0);
  const lon1 = (p1.lng ?? p1.longitude ?? p1[0]) * (Math.PI / 180.0);
  const lat2 = (p2.lat ?? p2.latitude ?? p2[1]) * (Math.PI / 180.0);
  const lon2 = (p2.lng ?? p2.longitude ?? p2[0]) * (Math.PI / 180.0);

  if (lat1 === lat2 && lon1 === lon2) return 0.0;

  const dLat = lat2 - lat1;
  const dLon = lon2 - lon1;

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) * Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(Math.max(0, Math.min(1, a))), Math.sqrt(Math.max(0, 1 - a)));
  return EARTH_RADIUS_METERS * c;
}

/**
 * Calculates total route distance in meters along a sequence of GPS points.
 */
function calculateRouteDistance(points) {
  if (!points || points.length < 2) return 0.0;
  let totalDistance = 0.0;
  for (let i = 0; i < points.length - 1; i++) {
    totalDistance += haversineDistance(points[i], points[i + 1]);
  }
  return totalDistance;
}

/**
 * Standardizes a point into GeoJSON [lng, lat] coordinate array.
 */
function toGeoJsonCoordinate(pt) {
  if (Array.isArray(pt)) {
    return [Number(pt[0]), Number(pt[1])];
  }
  const lng = pt.lng ?? pt.longitude;
  const lat = pt.lat ?? pt.latitude;
  return [Number(lng), Number(lat)];
}

/**
 * Validates a GPS route and generates a clean GeoJSON Polygon according to game rules.
 * 
 * Rules:
 * - Minimum route distance >= 100 meters
 * - End point within 10 meters of start point
 * - At least 3 unique non-collinear vertices
 * - No self-intersections (figure-8 loops rejected via turf.kinks)
 * - Non-zero area (rejects degenerate flat lines / spikes)
 * 
 * @param {Array} points - Array of GPS points [{lat, lng}, ...] or [[lng, lat], ...]
 * @param {Object} options - { minDistanceMeters, returnToleranceMeters }
 * @returns {Object} { isValid, reason, pathDistanceMeters, returnDistanceMeters, polygon, areaKm2, areaMeters, perimeterKm }
 */
function validatePolygon(points, options = {}) {
  const minDistance = options.minDistanceMeters ?? MIN_ROUTE_DISTANCE_METERS;
  const returnTolerance = options.returnToleranceMeters ?? RETURN_TOLERANCE_METERS;

  if (!points || !Array.isArray(points) || points.length < 4) {
    return {
      isValid: false,
      reason: 'Incomplete loop: minimum 4 GPS coordinates required to form a polygon.',
      pathDistanceMeters: calculateRouteDistance(points),
      returnDistanceMeters: null,
      polygon: null,
      areaKm2: 0,
      areaMeters: 0,
      perimeterKm: 0
    };
  }

  // 1. Validate individual coordinate numbers and ranges
  const rawCoords = [];
  for (let i = 0; i < points.length; i++) {
    const coord = toGeoJsonCoordinate(points[i]);
    const lng = coord[0];
    const lat = coord[1];

    if (isNaN(lat) || isNaN(lng) || !isFinite(lat) || !isFinite(lng)) {
      return {
        isValid: false,
        reason: `Invalid coordinate at index ${i}: NaN or Infinite coordinate encountered.`,
        pathDistanceMeters: 0,
        returnDistanceMeters: null,
        polygon: null
      };
    }

    if (lat < -90.0 || lat > 90.0) {
      return {
        isValid: false,
        reason: `Invalid coordinate at index ${i}: latitude ${lat} is out of bounds [-90, 90].`,
        pathDistanceMeters: 0,
        returnDistanceMeters: null,
        polygon: null
      };
    }

    if (lng < -180.0 || lng > 180.0) {
      return {
        isValid: false,
        reason: `Invalid coordinate at index ${i}: longitude ${lng} is out of bounds [-180, 180].`,
        pathDistanceMeters: 0,
        returnDistanceMeters: null,
        polygon: null
      };
    }

    rawCoords.push(coord);
  }

  // 2. Gameplay Rule 1: Minimum route distance (100m)
  const pathDistanceMeters = calculateRouteDistance(rawCoords);
  if (pathDistanceMeters < minDistance) {
    return {
      isValid: false,
      reason: `Route distance (${pathDistanceMeters.toFixed(1)}m) is less than the minimum required distance of ${minDistance}m.`,
      pathDistanceMeters,
      returnDistanceMeters: haversineDistance(rawCoords[0], rawCoords[rawCoords.length - 1]),
      polygon: null
    };
  }

  // 3. Gameplay Rule 2: Finish within 10 metres of start point
  const startPt = rawCoords[0];
  const endPt = rawCoords[rawCoords.length - 1];
  const returnDistanceMeters = haversineDistance(startPt, endPt);

  if (returnDistanceMeters > returnTolerance) {
    return {
      isValid: false,
      reason: `Incomplete loop: finish point is ${returnDistanceMeters.toFixed(1)}m from start point (must close within ${returnTolerance}m).`,
      pathDistanceMeters,
      returnDistanceMeters,
      polygon: null
    };
  }

  // 4. Check for at least 3 unique vertices
  const uniquePositions = [];
  for (const c of rawCoords) {
    const isDuplicate = uniquePositions.some(
      u => Math.abs(u[0] - c[0]) < 1e-8 && Math.abs(u[1] - c[1]) < 1e-8
    );
    if (!isDuplicate) {
      uniquePositions.push(c);
    }
  }

  if (uniquePositions.length < 3) {
    return {
      isValid: false,
      reason: 'Degenerate polygon: route contains fewer than 3 unique vertices.',
      pathDistanceMeters,
      returnDistanceMeters,
      polygon: null
    };
  }

  // 5. Ensure linear ring is strictly closed (first === last)
  const ringCoords = [...rawCoords];
  const first = ringCoords[0];
  const last = ringCoords[ringCoords.length - 1];
  if (first[0] !== last[0] || first[1] !== last[1]) {
    ringCoords.push([first[0], first[1]]);
  }

  let polygonFeature;
  try {
    polygonFeature = turf.polygon([ringCoords]);
  } catch (err) {
    return {
      isValid: false,
      reason: `Failed to construct GeoJSON polygon: ${err.message}`,
      pathDistanceMeters,
      returnDistanceMeters,
      polygon: null
    };
  }

  // 6. Gameplay Rule 3: Reject self-intersecting (figure-8) polygons
  const kinks = turf.kinks(polygonFeature);
  if (kinks.features.length > 0) {
    return {
      isValid: false,
      reason: `Degenerate polygon: route self-intersects ${kinks.features.length} time(s) (figure-8 and self-crossing loops are not allowed).`,
      pathDistanceMeters,
      returnDistanceMeters,
      polygon: null
    };
  }

  // 7. Area and degenerate check (e.g. collinear points / zero area)
  const areaMeters = turf.area(polygonFeature);
  if (areaMeters < MIN_POLYGON_AREA_METERS) {
    return {
      isValid: false,
      reason: `Degenerate polygon: enclosed area (${areaMeters.toFixed(2)} m²) is near zero or collinear.`,
      pathDistanceMeters,
      returnDistanceMeters,
      polygon: null
    };
  }

  const areaKm2 = areaMeters / 1000000.0;
  const perimeterKm = pathDistanceMeters / 1000.0;

  return {
    isValid: true,
    reason: 'Valid conquest loop completed.',
    pathDistanceMeters,
    returnDistanceMeters,
    areaMeters,
    areaKm2,
    perimeterKm,
    polygon: {
      type: 'Polygon',
      coordinates: polygonFeature.geometry.coordinates
    }
  };
}

/**
 * Validates the recorded activity against anti-cheat and movement rules before awarding territory.
 * 
 * @param {Array} points - Recorded GPS telemetry points
 * @param {Object} metadata - Activity metadata (isMockLocation, clientFlags, etc.)
 * @returns {Object} { passed: boolean, trustScore, validationStatus, reason }
 */
function validateActivityForConquest(points, metadata = {}) {
  const trust = evaluateActivityTrust(points, metadata);

  if (trust.validationStatus === 'rejected' || trust.trustScore < 50) {
    return {
      passed: false,
      trustScore: trust.trustScore,
      validationStatus: trust.validationStatus,
      reason: `Activity rejected by anti-cheat engine: trust score is ${trust.trustScore}% (${trust.issues.join('; ')}).`
    };
  }

  return {
    passed: true,
    trustScore: trust.trustScore,
    validationStatus: trust.validationStatus,
    reason: 'Activity validated successfully.'
  };
}

/**
 * Converts a GeoJSON geometry or raw coords into a standardized Turf Feature (Polygon or MultiPolygon).
 */
function toTurfFeature(geometry) {
  if (!geometry) return null;
  if (geometry.type === 'Feature') return geometry;
  if (geometry.type === 'Polygon') return turf.polygon(geometry.coordinates);
  if (geometry.type === 'MultiPolygon') return turf.multiPolygon(geometry.coordinates);
  if (Array.isArray(geometry) && Array.isArray(geometry[0])) {
    return turf.polygon(geometry);
  }
  return turf.feature(geometry);
}

/**
 * Processes territory capture and geometric difference:
 * - Slices overlapping land from active enemy territories.
 * - Enemy only loses the exact overlapping region.
 * - Slices that fragment an enemy territory automatically convert to MultiPolygon.
 * - Merges new loop into attacker's empire (supporting multiple disconnected polygons via MultiPolygon).
 * 
 * @param {Object} params - { newPolygon, existingTerritories, attackerId, attackerName, attackerColor }
 * @returns {Object} Slicing result
 */
function processTerritoryCapture({
  newPolygon,
  existingTerritories = [],
  attackerId,
  attackerName = 'Commander',
  attackerColor = '#3B82F6'
}) {
  const newPolyFeature = toTurfFeature(newPolygon);
  const loopAreaKm2 = turf.area(newPolyFeature) / 1000000.0;

  let totalStolenFromEnemiesKm2 = 0;
  const affectedDefenders = [];

  // 1. Process Enemy Overlaps (Slice and Subtract)
  for (const territory of existingTerritories) {
    if (!territory || territory.status !== 'active') continue;

    const territoryOwnerId = (territory.ownerId?._id ?? territory.ownerId)?.toString();
    const isEnemy = territoryOwnerId !== attackerId.toString();

    if (!isEnemy) continue;

    try {
      const enemyFeature = toTurfFeature(territory.geometry);
      if (!enemyFeature) continue;

      // Calculate intersection (only overlapping territory is captured!)
      const intersection = turf.intersect(enemyFeature, newPolyFeature);

      if (intersection) {
        const overlapAreaKm2 = turf.area(intersection) / 1000000.0;

        if (overlapAreaKm2 >= MIN_OVERLAP_AREA_KM2) {
          totalStolenFromEnemiesKm2 += overlapAreaKm2;

          // Compute remaining geometry: Enemy_New = Enemy_Old - New_Polygon
          const remainingFeature = turf.difference(enemyFeature, newPolyFeature);

          let remainingGeometry = null;
          let remainingAreaKm2 = 0.0;
          let isFullyCaptured = false;

          if (!remainingFeature) {
            // Completely swallowed
            isFullyCaptured = true;
          } else {
            remainingAreaKm2 = turf.area(remainingFeature) / 1000000.0;
            if (remainingAreaKm2 < MIN_OVERLAP_AREA_KM2) {
              isFullyCaptured = true;
            } else {
              remainingGeometry = remainingFeature.geometry;
            }
          }

          affectedDefenders.push({
            territoryId: territory._id ?? territory.id,
            defenderId: territory.ownerId,
            defenderName: territory.ownerName ?? 'Rival Player',
            lostAreaKm2: overlapAreaKm2,
            remainingAreaKm2: isFullyCaptured ? 0.0 : remainingAreaKm2,
            remainingGeometry,
            status: isFullyCaptured ? 'captured' : 'active'
          });
        }
      }
    } catch (err) {
      console.error(`Error calculating spatial difference for territory ${territory._id ?? territory.id}:`, err.message);
    }
  }

  // 2. Process Attacker Territory Expansion (Merge or MultiPolygon)
  // Check if attacker already owns an active territory
  const attackerExistingTerritory = existingTerritories.find(
    t => (t.ownerId?._id ?? t.ownerId)?.toString() === attackerId.toString() && t.status === 'active'
  );

  let updatedAttackerGeometry;
  let updatedAttackerAreaKm2;

  if (attackerExistingTerritory) {
    try {
      const existingAttackerFeature = toTurfFeature(attackerExistingTerritory.geometry);
      // turf.union seamlessly handles both overlapping (merging) and disconnected (MultiPolygon)
      const unionResult = turf.union(existingAttackerFeature, newPolyFeature);
      updatedAttackerGeometry = unionResult.geometry;
      updatedAttackerAreaKm2 = turf.area(unionResult) / 1000000.0;
    } catch (_) {
      // Fallback: manually wrap into MultiPolygon if union threw
      const existingCoords = attackerExistingTerritory.geometry.type === 'MultiPolygon'
        ? attackerExistingTerritory.geometry.coordinates
        : [attackerExistingTerritory.geometry.coordinates];
      updatedAttackerGeometry = {
        type: 'MultiPolygon',
        coordinates: [...existingCoords, newPolygon.coordinates]
      };
      updatedAttackerAreaKm2 = (attackerExistingTerritory.areaKm2 ?? 0) + loopAreaKm2;
    }
  } else {
    updatedAttackerGeometry = newPolygon;
    updatedAttackerAreaKm2 = loopAreaKm2;
  }

  return {
    loopAreaKm2,
    stolenFromEnemiesKm2: totalStolenFromEnemiesKm2,
    affectedDefenders,
    attackerTerritory: {
      ownerId: attackerId,
      ownerName: attackerName,
      color: attackerColor,
      geometry: updatedAttackerGeometry,
      areaKm2: updatedAttackerAreaKm2,
      perimeterKm: 0,
      status: 'active',
      isMultiPolygon: updatedAttackerGeometry.type === 'MultiPolygon'
    }
  };
}

/**
 * Mutex / Concurrency Lock Manager:
 * Serializes territory claims across concurrent requests to prevent race conditions and lost updates.
 */
class AsyncClaimLock {
  constructor() {
    this._queue = Promise.resolve();
  }

  /**
   * Executes an asynchronous task exclusively in sequential FIFO order.
   * @param {Function} task - Async function to run exclusively
   */
  acquire(task) {
    const next = this._queue.then(() => task());
    this._queue = next.catch(() => {});
    return next;
  }
}

const globalClaimLock = new AsyncClaimLock();

/**
 * Top-level Orchestrator: Safely claims territory from an activity submission.
 * Enforces all game rules, anti-cheat validation, geometric slicing, and concurrency safety.
 * 
 * @param {Object} params - { userId, username, userColor, points, steps, durationSeconds, activityType, storage }
 * @returns {Promise<Object>} Conquest result
 */
async function claimTerritory({
  userId,
  username = 'Commander',
  userColor = '#3B82F6',
  points,
  steps = 0,
  durationSeconds = 0,
  activityType = 'walking',
  storage = null // optional storage/memoryStore adapter
}) {
  return globalClaimLock.acquire(async () => {
    // 1. Validate recorded activity before awarding territory
    const activityValidation = validateActivityForConquest(points);
    if (!activityValidation.passed) {
      return {
        success: false,
        territoryAwarded: false,
        reason: activityValidation.reason,
        trustScore: activityValidation.trustScore,
        validationStatus: activityValidation.validationStatus
      };
    }

    // 2. Validate polygon and loop rules
    const loopValidation = validatePolygon(points);
    if (!loopValidation.isValid) {
      return {
        success: false,
        territoryAwarded: false,
        reason: loopValidation.reason,
        pathDistanceMeters: loopValidation.pathDistanceMeters,
        returnDistanceMeters: loopValidation.returnDistanceMeters
      };
    }

    // 3. Fetch active territories from MongoDB or provided storage
    let activeTerritories = [];
    if (mongoose.connection && mongoose.connection.readyState === 1 && Territory && Territory.find) {
      try {
        activeTerritories = await Territory.find({ status: 'active' }).lean();
      } catch (_) {
        // Fallback to storage or memory store
      }
    }

    if (activeTerritories.length === 0 && storage && storage.territories) {
      activeTerritories = storage.territories.filter(t => t.status === 'active');
    }

    // 4. Process geometric capture and slicing
    const captureResult = processTerritoryCapture({
      newPolygon: loopValidation.polygon,
      existingTerritories: activeTerritories,
      attackerId: userId,
      attackerName: username,
      attackerColor: userColor
    });

    // 5. Concurrency-safe persistence update
    // Update affected defenders in DB or store
    for (const defender of captureResult.affectedDefenders) {
      if (mongoose.connection && mongoose.connection.readyState === 1 && Territory && Territory.findOneAndUpdate) {
        try {
          await Territory.findOneAndUpdate(
            { _id: defender.territoryId },
            {
              $set: {
                geometry: defender.remainingGeometry ?? { type: 'Polygon', coordinates: [] },
                areaKm2: defender.remainingAreaKm2,
                status: defender.status,
                updatedAt: new Date()
              },
              $inc: { version: 1 }
            }
          );
        } catch (_) {}
      }

      if (storage && storage.territories) {
        const memDefender = storage.territories.find(
          t => (t.id ?? t._id)?.toString() === defender.territoryId.toString()
        );
        if (memDefender) {
          memDefender.status = defender.status;
          memDefender.areaKm2 = defender.remainingAreaKm2;
          if (defender.remainingGeometry) {
            memDefender.geometry = defender.remainingGeometry;
          }
          memDefender.version = (memDefender.version || 1) + 1;
        }
      }
    }

    // Update or Insert Attacker Territory
    let savedAttackerTerritory;
    if (mongoose.connection && mongoose.connection.readyState === 1 && Territory && Territory.findOneAndUpdate) {
      try {
        savedAttackerTerritory = await Territory.findOneAndUpdate(
          { ownerId: userId, status: 'active' },
          {
            $set: {
              ownerName: username,
              color: userColor,
              geometry: captureResult.attackerTerritory.geometry,
              areaKm2: captureResult.attackerTerritory.areaKm2,
              status: 'active',
              updatedAt: new Date()
            },
            $inc: { version: 1 }
          },
          { upsert: true, new: true }
        );
      } catch (_) {}
    }

    if (storage && storage.territories) {
      const existing = storage.territories.find(
        t => (t.ownerId?._id ?? t.ownerId)?.toString() === userId.toString() && t.status === 'active'
      );
      if (existing) {
        existing.geometry = captureResult.attackerTerritory.geometry;
        existing.areaKm2 = captureResult.attackerTerritory.areaKm2;
        existing.version = (existing.version || 1) + 1;
        savedAttackerTerritory = existing;
      } else {
        const newTerr = {
          id: 't_' + Date.now(),
          ownerId: userId,
          ownerName: username,
          color: userColor,
          geometry: captureResult.attackerTerritory.geometry,
          areaKm2: captureResult.attackerTerritory.areaKm2,
          status: 'active',
          version: 1,
          createdAt: new Date()
        };
        storage.territories.push(newTerr);
        savedAttackerTerritory = newTerr;
      }
    }

    return {
      success: true,
      territoryAwarded: true,
      loopDetails: {
        pathDistanceMeters: loopValidation.pathDistanceMeters,
        returnDistanceMeters: loopValidation.returnDistanceMeters,
        areaMeters: loopValidation.areaMeters,
        areaKm2: loopValidation.areaKm2
      },
      captureDetails: {
        newLoopAreaKm2: captureResult.loopAreaKm2,
        stolenFromEnemiesKm2: captureResult.stolenFromEnemiesKm2,
        affectedDefenders: captureResult.affectedDefenders,
        attackerTerritory: savedAttackerTerritory ?? captureResult.attackerTerritory
      }
    };
  });
}

module.exports = {
  haversineDistance,
  calculateRouteDistance,
  validatePolygon,
  validateActivityForConquest,
  processTerritoryCapture,
  claimTerritory,
  AsyncClaimLock,
  globalClaimLock,
  MIN_ROUTE_DISTANCE_METERS,
  RETURN_TOLERANCE_METERS
};
