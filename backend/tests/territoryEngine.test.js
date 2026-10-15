/**
 * CONQUER — Geospatial Territory Engine Test Suite
 * 
 * Comprehensive tests for:
 * 1. Minimum route distance rule (>= 100m)
 * 2. Finish distance tolerance rule (<= 10m)
 * 3. Rejection of invalid/degenerate polygons (figure-8, self-intersecting, collinear, < 3 points)
 * 4. Activity anti-cheat validation before awarding territory
 * 5. Overlap capture (slicing enemy territory, leaving non-overlapping land intact, no capture on open walk-through)
 * 6. Disconnected MultiPolygon support per player
 * 7. Safe concurrent claim execution
 * 8. Strict GeoJSON [lng, lat] coordinate conformance
 */

const { test, describe, beforeEach } = require('node:test');
const assert = require('node:assert');
const turf = require('@turf/turf');
const {
  haversineDistance,
  calculateRouteDistance,
  validatePolygon,
  validateActivityForConquest,
  processTerritoryCapture,
  claimTerritory,
  MIN_ROUTE_DISTANCE_METERS,
  RETURN_TOLERANCE_METERS
} = require('../services/territoryEngine');

// Helper to create square polygon coordinates around [lng, lat]
// 0.001 deg latitude is ~111.2 meters
function createSquareLoop(centerLng, centerLat, sizeDeg = 0.001) {
  const half = sizeDeg / 2;
  const p1 = [centerLng - half, centerLat - half];
  const p2 = [centerLng + half, centerLat - half];
  const p3 = [centerLng + half, centerLat + half];
  const p4 = [centerLng - half, centerLat + half];
  const pClose = [centerLng - half, centerLat - half]; // closes at p1
  return [p1, p2, p3, p4, pClose];
}

describe('CONQUER Geospatial Territory Engine Tests', () => {

  describe('1. Minimum Route Distance Rule (100 metres)', () => {
    test('Rejects route with path distance < 100m', () => {
      // Tiny loop: ~0.0001 deg offset (~11m per side => total ~44m < 100m)
      const tinyLoop = createSquareLoop(74.740, 13.340, 0.0001);
      const result = validatePolygon(tinyLoop);

      assert.strictEqual(result.isValid, false);
      assert.match(result.reason, /less than the minimum required distance of 100m/i);
      assert.ok(result.pathDistanceMeters < 100, `Expected < 100m, got ${result.pathDistanceMeters}`);
      assert.strictEqual(result.polygon, null);
    });

    test('Accepts route with path distance >= 100m', () => {
      // Sized loop: 0.001 deg offset (~111m per side => total ~444m > 100m)
      const validLoop = createSquareLoop(74.740, 13.340, 0.001);
      const result = validatePolygon(validLoop);

      assert.strictEqual(result.isValid, true);
      assert.ok(result.pathDistanceMeters >= 100, `Expected >= 100m, got ${result.pathDistanceMeters}`);
      assert.ok(result.polygon !== null);
      assert.strictEqual(result.polygon.type, 'Polygon');
    });
  });

  describe('2. Finish Distance Tolerance Rule (10 metres)', () => {
    test('Rejects route where finish point is > 10m from start point (incomplete loop)', () => {
      // Open route: starts at (74.7400, 13.3400), finishes at (74.7400, 13.3403) (~33m away)
      const openRoute = [
        [74.7400, 13.3400],
        [74.7410, 13.3400],
        [74.7410, 13.3410],
        [74.7400, 13.3410],
        [74.7400, 13.3403] // ~33m from start!
      ];

      const result = validatePolygon(openRoute);
      assert.strictEqual(result.isValid, false);
      assert.match(result.reason, /must close within 10m/i);
      assert.ok(result.returnDistanceMeters > 10);
      assert.strictEqual(result.polygon, null);
    });

    test('Accepts route where finish point is within 10m of start point', () => {
      // Starts at (74.74000, 13.34000), ends at (74.74000, 13.34004) (~4.4m away, <= 10m)
      const nearCloseRoute = [
        [74.74000, 13.34000],
        [74.74100, 13.34000],
        [74.74100, 13.34100],
        [74.74000, 13.34100],
        [74.74000, 13.34004] // ~4.4m from start!
      ];

      const result = validatePolygon(nearCloseRoute);
      assert.strictEqual(result.isValid, true);
      assert.ok(result.returnDistanceMeters <= 10);
      assert.ok(result.polygon !== null);
    });
  });

  describe('3. Rejection of Invalid or Degenerate Polygons', () => {
    test('Rejects routes with fewer than 3 unique vertices (back-and-forth line)', () => {
      // Walking out 60m and returning on the same line (2 unique points)
      const lineRoute = [
        [74.7400, 13.3400],
        [74.7400, 13.3406],
        [74.7400, 13.3400]
      ];

      const result = validatePolygon(lineRoute);
      assert.strictEqual(result.isValid, false);
      assert.match(result.reason, /minimum 4 GPS coordinates|fewer than 3 unique/i);
    });

    test('Rejects collinear points forming a zero-area flat line', () => {
      // 4 points on a straight line, then back to start
      const flatLine = [
        [74.7400, 13.3400],
        [74.7400, 13.3405],
        [74.7400, 13.3410],
        [74.7400, 13.3400]
      ];

      const result = validatePolygon(flatLine);
      assert.strictEqual(result.isValid, false);
      assert.match(result.reason, /near zero or collinear|degenerate/i);
    });

    test('Rejects self-intersecting (figure-8) polygons', () => {
      // Figure-8 crossing in the middle
      const figure8 = [
        [74.7400, 13.3400],
        [74.7420, 13.3420],
        [74.7420, 13.3400],
        [74.7400, 13.3420],
        [74.7400, 13.3400]
      ];

      const result = validatePolygon(figure8);
      assert.strictEqual(result.isValid, false);
      assert.match(result.reason, /self-intersects/i);
      assert.strictEqual(result.polygon, null);
    });

    test('Rejects invalid latitude/longitude or NaN coordinates', () => {
      const nanRoute = [
        [NaN, 13.3400],
        [74.7410, 13.3400],
        [74.7410, 13.3410],
        [74.7400, 13.3400]
      ];

      const outOfBoundsRoute = [
        [74.7400, 95.0000], // Lat > 90
        [74.7410, 95.0000],
        [74.7410, 95.0010],
        [74.7400, 95.0000]
      ];

      assert.strictEqual(validatePolygon(nanRoute).isValid, false);
      assert.strictEqual(validatePolygon(outOfBoundsRoute).isValid, false);
    });
  });

  describe('4. Activity Validation Before Awarding Territory', () => {
    test('Rejects activity with teleportation violations or vehicle speeds', () => {
      const startTime = new Date();
      // Points 2km apart with 1 second gap (7200 km/h teleportation)
      const suspiciousPoints = [
        { lat: 13.3400, lng: 74.7400, timestamp: startTime },
        { lat: 13.3580, lng: 74.7400, timestamp: new Date(startTime.getTime() + 1000) }
      ];

      const validation = validateActivityForConquest(suspiciousPoints);
      assert.strictEqual(validation.passed, false);
      assert.strictEqual(validation.validationStatus, 'rejected');
      assert.match(validation.reason, /rejected by anti-cheat/i);
    });

    test('Approves normal human walking/running activity', () => {
      const startTime = new Date();
      // 4 points spaced ~30m apart with 15s between them (~7.2 km/h)
      const normalPoints = [
        { lat: 13.3400, lng: 74.7400, timestamp: startTime },
        { lat: 13.3403, lng: 74.7400, timestamp: new Date(startTime.getTime() + 15000) },
        { lat: 13.3403, lng: 74.7403, timestamp: new Date(startTime.getTime() + 30000) },
        { lat: 13.3400, lng: 74.7400, timestamp: new Date(startTime.getTime() + 45000) }
      ];

      const validation = validateActivityForConquest(normalPoints);
      assert.strictEqual(validation.passed, true);
      assert.strictEqual(validation.validationStatus, 'passed');
      assert.ok(validation.trustScore >= 80);
    });
  });

  describe('5. Territory Overlap & Slicing (Capture Only Overlapping Territory)', () => {
    test('Walking through territory does not capture it if loop is incomplete', async () => {
      const storage = {
        territories: [
          {
            id: 't_enemy_1',
            ownerId: 'u_enemy',
            ownerName: 'RIVAL_DRAKE',
            color: '#EF4444',
            areaKm2: 0.5,
            status: 'active',
            geometry: turf.polygon([[[74.740, 13.340], [74.745, 13.340], [74.745, 13.345], [74.740, 13.345], [74.740, 13.340]]]).geometry
          }
        ]
      };

      // Open walk through enemy territory from south to north (not closed!)
      // Spaced ~30m apart with 25s intervals (~4.3 km/h walking speed)
      const baseTime = Date.now();
      const walkThroughPoints = [
        { lat: 13.3400, lng: 74.7420, timestamp: new Date(baseTime) },
        { lat: 13.3403, lng: 74.7420, timestamp: new Date(baseTime + 25000) },
        { lat: 13.3406, lng: 74.7420, timestamp: new Date(baseTime + 50000) },
        { lat: 13.3412, lng: 74.7420, timestamp: new Date(baseTime + 75000) } // finishes far away (> 100m)
      ];

      const result = await claimTerritory({
        userId: 'u_player',
        username: 'PLAYER_ONE',
        points: walkThroughPoints,
        storage
      });

      assert.strictEqual(result.success, false);
      assert.strictEqual(result.territoryAwarded, false);
      assert.match(result.reason, /Incomplete loop/i);

      // Verify enemy territory was NOT touched
      assert.strictEqual(storage.territories[0].status, 'active');
      assert.strictEqual(storage.territories[0].areaKm2, 0.5);
    });

    test('Closed loop overlapping enemy territory captures ONLY the overlapping slice', () => {
      // Enemy territory: Box from [0, 0] to [2, 2]
      const enemyTerritory = {
        id: 't_enemy_alpha',
        ownerId: 'u_enemy',
        ownerName: 'DRAKE',
        status: 'active',
        geometry: turf.polygon([[[0, 0], [2, 0], [2, 2], [0, 2], [0, 0]]]).geometry
      };

      // Attacker loops box from [1, 1] to [3, 3] (overlaps upper-right quadrant of enemy: [1..2, 1..2])
      const attackerPolygon = turf.polygon([[[1, 1], [3, 1], [3, 3], [1, 3], [1, 1]]]).geometry;

      const capture = processTerritoryCapture({
        newPolygon: attackerPolygon,
        existingTerritories: [enemyTerritory],
        attackerId: 'u_attacker',
        attackerName: 'CONQUEROR'
      });

      assert.ok(capture.stolenFromEnemiesKm2 > 0, 'Expected stolen area > 0');
      assert.strictEqual(capture.affectedDefenders.length, 1);

      const defender = capture.affectedDefenders[0];
      assert.strictEqual(defender.defenderId, 'u_enemy');
      assert.strictEqual(defender.status, 'active'); // still has 3/4 of their territory
      assert.ok(defender.remainingAreaKm2 > 0);
      assert.ok(defender.lostAreaKm2 > 0);

      // Verify enemy remaining geometry no longer contains the overlapping area
      const remainingFeature = turf.feature(defender.remainingGeometry);
      const overlapCheck = turf.intersect(remainingFeature, turf.feature(attackerPolygon));
      // Overlap with remaining should now be null or 0
      assert.ok(!overlapCheck || turf.area(overlapCheck) < 1.0);
    });

    test('Completely enclosed enemy territory is fully captured', () => {
      // Enemy territory: Small box from [1, 1] to [2, 2]
      const enemySmall = {
        id: 't_small',
        ownerId: 'u_enemy',
        ownerName: 'DEFENDER',
        status: 'active',
        geometry: turf.polygon([[[1, 1], [2, 1], [2, 2], [1, 2], [1, 1]]]).geometry
      };

      // Attacker forms a giant loop from [0, 0] to [5, 5] enclosing small box completely
      const giantAttackerPoly = turf.polygon([[[0, 0], [5, 0], [5, 5], [0, 5], [0, 0]]]).geometry;

      const capture = processTerritoryCapture({
        newPolygon: giantAttackerPoly,
        existingTerritories: [enemySmall],
        attackerId: 'u_giant'
      });

      assert.strictEqual(capture.affectedDefenders.length, 1);
      const defender = capture.affectedDefenders[0];
      assert.strictEqual(defender.status, 'captured');
      assert.strictEqual(defender.remainingAreaKm2, 0.0);
      assert.strictEqual(defender.remainingGeometry, null);
    });
  });

  describe('6. Multiple Disconnected Polygons per Player (MultiPolygon Support)', () => {
    test('Combines disconnected claims into a valid GeoJSON MultiPolygon', () => {
      // Player already has territory at Region A: [0, 0] to [2, 2]
      const existingPlayerTerritory = {
        id: 't_player_initial',
        ownerId: 'u_player_multi',
        ownerName: 'MULTILORD',
        status: 'active',
        areaKm2: 0.1,
        geometry: turf.polygon([[[0, 0], [2, 0], [2, 2], [0, 2], [0, 0]]]).geometry
      };

      // Player completes disconnected loop at Region B: [10, 10] to [12, 12]
      const disconnectedPoly = turf.polygon([[[10, 10], [12, 10], [12, 12], [10, 12], [10, 10]]]).geometry;

      const capture = processTerritoryCapture({
        newPolygon: disconnectedPoly,
        existingTerritories: [existingPlayerTerritory],
        attackerId: 'u_player_multi'
      });

      assert.strictEqual(capture.attackerTerritory.geometry.type, 'MultiPolygon');
      assert.strictEqual(capture.attackerTerritory.isMultiPolygon, true);
      assert.strictEqual(capture.attackerTerritory.geometry.coordinates.length, 2);

      // Area should equal sum of both disconnected squares
      const poly1Area = turf.area(turf.polygon([[[0, 0], [2, 0], [2, 2], [0, 2], [0, 0]]]));
      const poly2Area = turf.area(turf.polygon([[[10, 10], [12, 10], [12, 12], [10, 12], [10, 10]]]));
      const totalExpectedKm2 = (poly1Area + poly2Area) / 1000000;

      assert.ok(
        Math.abs(capture.attackerTerritory.areaKm2 - totalExpectedKm2) < 0.01,
        `Expected ${totalExpectedKm2}, got ${capture.attackerTerritory.areaKm2}`
      );
    });

    test('Merges overlapping claims into a unified single polygon', () => {
      // Player already owns [0, 0] to [2, 2]
      const existingPlayerTerritory = {
        id: 't_player_1',
        ownerId: 'u_merger',
        status: 'active',
        geometry: turf.polygon([[[0, 0], [2, 0], [2, 2], [0, 2], [0, 0]]]).geometry
      };

      // Player completes an adjacent, overlapping loop: [1, 1] to [3, 3]
      const overlappingPoly = turf.polygon([[[1, 1], [3, 1], [3, 3], [1, 3], [1, 1]]]).geometry;

      const capture = processTerritoryCapture({
        newPolygon: overlappingPoly,
        existingTerritories: [existingPlayerTerritory],
        attackerId: 'u_merger'
      });

      // Turf.union of overlapping polygons yields a single Polygon
      assert.strictEqual(capture.attackerTerritory.geometry.type, 'Polygon');
      assert.strictEqual(capture.attackerTerritory.isMultiPolygon, false);
    });
  });

  describe('7. Safe Concurrent Claim Handling', () => {
    test('Simultaneous concurrent claims execute safely in serialized order without race conditions', async () => {
      const victimGeometry = turf.polygon([[[0, 0], [0.006, 0], [0.006, 0.006], [0, 0.006], [0, 0]]]).geometry;
      const initialVictimAreaKm2 = turf.area(turf.feature(victimGeometry)) / 1000000.0;

      const storage = {
        territories: [
          {
            id: 't_shared_enemy',
            ownerId: 'u_victim',
            ownerName: 'VICTIM',
            status: 'active',
            areaKm2: initialVictimAreaKm2,
            version: 1,
            geometry: victimGeometry
          }
        ]
      };

      // Player 1 claims slice [0, 0] to [2, 2] (south-west corner)
      // Path distance ~888m at normal walking speed (~5 km/h)
      const t1 = Date.now();
      const p1Loop = [
        { lat: 0.000, lng: 0.000, timestamp: new Date(t1) },
        { lat: 0.000, lng: 0.002, timestamp: new Date(t1 + 160000) },
        { lat: 0.002, lng: 0.002, timestamp: new Date(t1 + 320000) },
        { lat: 0.002, lng: 0.000, timestamp: new Date(t1 + 480000) },
        { lat: 0.000, lng: 0.000, timestamp: new Date(t1 + 640000) }
      ];

      // Player 2 claims slice [2, 2] to [4, 4] (north-east corner)
      const t2 = Date.now();
      const p2Loop = [
        { lat: 0.002, lng: 0.002, timestamp: new Date(t2) },
        { lat: 0.002, lng: 0.004, timestamp: new Date(t2 + 160000) },
        { lat: 0.004, lng: 0.004, timestamp: new Date(t2 + 320000) },
        { lat: 0.004, lng: 0.002, timestamp: new Date(t2 + 480000) },
        { lat: 0.002, lng: 0.002, timestamp: new Date(t2 + 640000) }
      ];

      // Fire both claims concurrently with Promise.all
      const [res1, res2] = await Promise.all([
        claimTerritory({
          userId: 'u_concurrent_1',
          username: 'ALPHA',
          points: p1Loop,
          storage
        }),
        claimTerritory({
          userId: 'u_concurrent_2',
          username: 'BETA',
          points: p2Loop,
          storage
        })
      ]);

      // Both claims must have succeeded
      assert.strictEqual(res1.success, true);
      assert.strictEqual(res1.territoryAwarded, true);
      assert.strictEqual(res2.success, true);
      assert.strictEqual(res2.territoryAwarded, true);

      // Attacker 1 territory created
      const terr1 = storage.territories.find(t => t.ownerId === 'u_concurrent_1');
      assert.ok(terr1, 'Attacker 1 territory should exist');

      // Attacker 2 territory created
      const terr2 = storage.territories.find(t => t.ownerId === 'u_concurrent_2');
      assert.ok(terr2, 'Attacker 2 territory should exist');

      // Victim territory updated twice (version incremented)
      const victim = storage.territories.find(t => t.ownerId === 'u_victim');
      assert.strictEqual(victim.version, 3); // initial 1 + claim1 + claim2
      assert.ok(victim.areaKm2 < initialVictimAreaKm2, 'Victim area should be reduced after both slices');
    });
  });

  describe('8. GeoJSON Specification Conformance', () => {
    test('Generated territory geometries strictly conform to GeoJSON Polygon / MultiPolygon specification', () => {
      const loopCoords = createSquareLoop(74.740, 13.340, 0.002);
      const validation = validatePolygon(loopCoords);

      assert.strictEqual(validation.isValid, true);
      const poly = validation.polygon;

      assert.strictEqual(poly.type, 'Polygon');
      assert.ok(Array.isArray(poly.coordinates));
      assert.ok(Array.isArray(poly.coordinates[0]));

      // Verify each coordinate is [longitude, latitude]
      for (const pt of poly.coordinates[0]) {
        assert.strictEqual(pt.length, 2);
        const [lng, lat] = pt;
        assert.ok(lng >= -180 && lng <= 180, `Invalid lng: ${lng}`);
        assert.ok(lat >= -90 && lat <= 90, `Invalid lat: ${lat}`);
      }

      // Verify linear ring is strictly closed (first === last)
      const first = poly.coordinates[0][0];
      const last = poly.coordinates[0][poly.coordinates[0].length - 1];
      assert.strictEqual(first[0], last[0]);
      assert.strictEqual(first[1], last[1]);
    });
  });

});
