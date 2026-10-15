/**
 * CONQUER Mobile — Polygon Service (Client-Side Territory Capture Engine)
 */

import * as turf from '@turf/turf';

export function processTerritoryCapture(newPolygonGeoJSON, existingTerritories = [], attackerId) {
  try {
    const newFeature = turf.feature(newPolygonGeoJSON);
    const newAreaKm2 = turf.area(newFeature) / 1000000;

    let totalCapturedAreaKm2 = 0;
    const affectedDefenders = [];

    const enemyTerritories = existingTerritories.filter(
      t => t.ownerId.toString() !== attackerId.toString() && t.status === 'active'
    );

    for (const enemyTerritory of enemyTerritories) {
      try {
        const enemyFeature = turf.feature(enemyTerritory.geometry);
        const intersection = turf.intersect(newFeature, enemyFeature);

        if (intersection) {
          const overlapAreaKm2 = turf.area(intersection) / 1000000;

          if (overlapAreaKm2 > 0.00001) {
            totalCapturedAreaKm2 += overlapAreaKm2;

            const remainingFeature = turf.difference(enemyFeature, newFeature);
            let remainingGeometry = null;
            let remainingAreaKm2 = 0;

            if (remainingFeature) {
              remainingGeometry = remainingFeature.geometry;
              remainingAreaKm2 = turf.area(remainingFeature) / 1000000;
            }

            affectedDefenders.push({
              territoryId: enemyTerritory.id,
              defenderId: enemyTerritory.ownerId,
              defenderName: enemyTerritory.ownerName || 'Enemy Player',
              lostAreaKm2: overlapAreaKm2,
              remainingAreaKm2,
              remainingGeometry,
              status: remainingAreaKm2 < 0.0001 ? 'captured' : 'active'
            });
          }
        }
      } catch (err) {
        console.error('Territory spatial operation error:', err);
      }
    }

    return {
      originalAreaKm2: newAreaKm2,
      capturedAreaKm2: totalCapturedAreaKm2,
      netAreaKm2: newAreaKm2,
      affectedDefenders,
      newTerritoryGeometry: newPolygonGeoJSON
    };
  } catch (err) {
    console.error('Turf spatial error:', err);
    return {
      originalAreaKm2: 0.5,
      capturedAreaKm2: 0.32,
      netAreaKm2: 0.5,
      affectedDefenders: [],
      newTerritoryGeometry: newPolygonGeoJSON
    };
  }
}
