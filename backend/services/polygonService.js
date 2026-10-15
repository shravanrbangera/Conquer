/**
 * CONQUER — Polygon & Territory Slicing Engine
 * Manages spatial overlap, geometric difference (territory capture), and GeoJSON transformations.
 */

const turf = require('@turf/turf');

/**
 * Calculates geometric intersection and difference between a new conquest polygon and existing player territories.
 * 
 * @param {Object} newPolygonGeoJSON - GeoJSON Polygon feature of newly completed loop
 * @param {Array} existingTerritories - Array of active Territory documents/objects
 * @param {String} attackerId - User ID of attacking player
 * 
 * @returns {Object} Result of spatial analysis containing:
 *  - capturedAreaKm2: total overlapping land stolen from enemies
 *  - netAreaKm2: total new land added to attacker's empire
 *  - affectedDefenders: Array of { defenderId, territoryId, lostAreaKm2, remainingGeometry }
 *  - newTerritoryGeometry: GeoJSON Polygon/MultiPolygon of conquered region
 */
function processTerritoryCapture(newPolygonGeoJSON, existingTerritories = [], attackerId) {
  const newFeature = turf.feature(newPolygonGeoJSON);
  const newAreaKm2 = turf.area(newFeature) / 1000000;

  let totalCapturedAreaKm2 = 0;
  const affectedDefenders = [];

  // Filter out attacker's own existing territories (if overlapping own land, refresh or merge)
  const enemyTerritories = existingTerritories.filter(
    t => t.ownerId.toString() !== attackerId.toString() && t.status === 'active'
  );

  for (const enemyTerritory of enemyTerritories) {
    try {
      const enemyFeature = turf.feature(enemyTerritory.geometry);
      
      // Check if there is spatial intersection
      const intersection = turf.intersect(newFeature, enemyFeature);

      if (intersection) {
        const overlapAreaKm2 = turf.area(intersection) / 1000000;

        if (overlapAreaKm2 > 0.00001) { // minimum threshold (10 m²)
          totalCapturedAreaKm2 += overlapAreaKm2;

          // Compute remaining geometry for defender (Enemy_New = Enemy_Old - New_Polygon)
          const remainingFeature = turf.difference(enemyFeature, newFeature);

          let remainingGeometry = null;
          let remainingAreaKm2 = 0;

          if (remainingFeature) {
            remainingGeometry = remainingFeature.geometry;
            remainingAreaKm2 = turf.area(remainingFeature) / 1000000;
          }

          affectedDefenders.push({
            territoryId: enemyTerritory._id,
            defenderId: enemyTerritory.ownerId,
            defenderName: enemyTerritory.ownerName || 'Enemy Player',
            lostAreaKm2: overlapAreaKm2,
            remainingAreaKm2,
            remainingGeometry,
            status: remainingAreaKm2 < 0.0001 ? 'captured' : 'active' // fully swallowed or trimmed
          });
        }
      }
    } catch (err) {
      console.error('Territory spatial operation error:', err.message);
    }
  }

  return {
    originalAreaKm2: newAreaKm2,
    capturedAreaKm2: totalCapturedAreaKm2,
    netAreaKm2: newAreaKm2, // Full enclosed area becomes owned by attacker
    affectedDefenders,
    newTerritoryGeometry: newPolygonGeoJSON
  };
}

/**
 * Checks if a point [lng, lat] is inside any restricted zone.
 */
function isPointInRestrictedZone(point, restrictedZones = []) {
  const ptFeature = turf.point(point);
  for (const zone of restrictedZones) {
    try {
      const zoneFeature = turf.feature(zone.geometry);
      if (turf.booleanPointInPolygon(ptFeature, zoneFeature)) {
        return { isRestricted: true, zoneName: zone.name, reason: zone.reason };
      }
    } catch (err) {
      console.error('Restricted zone check error:', err.message);
    }
  }
  return { isRestricted: false };
}

module.exports = {
  processTerritoryCapture,
  isPointInRestrictedZone
};
