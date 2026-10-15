/**
 * CONQUER — Loop Detection Service
 * Core real-world loop detection and closed polygon calculation algorithms.
 */

// Earth radius in meters
const EARTH_RADIUS_M = 6371000;

/**
 * Calculates Haversine distance between two [lat, lng] or {lat, lng} coordinates in meters.
 */
function haversineDistance(p1, p2) {
  const lat1 = (p1.lat !== undefined ? p1.lat : p1[1]) * (Math.PI / 180);
  const lon1 = (p1.lng !== undefined ? p1.lng : p1[0]) * (Math.PI / 180);
  const lat2 = (p2.lat !== undefined ? p2.lat : p2[1]) * (Math.PI / 180);
  const lon2 = (p2.lng !== undefined ? p2.lng : p2[0]) * (Math.PI / 180);

  const dLat = lat2 - lat1;
  const dLon = lon2 - lon1;

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLon / 2) * Math.sin(dLon / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return EARTH_RADIUS_M * c;
}

/**
 * Calculates total cumulative distance along a sequence of GPS points in meters.
 * Points can be objects {lat, lng} or GeoJSON arrays [lng, lat].
 */
function calculatePathDistance(points) {
  if (!points || points.length < 2) return 0;
  let total = 0;
  for (let i = 0; i < points.length - 1; i++) {
    total += haversineDistance(points[i], points[i + 1]);
  }
  return total;
}

/**
 * Validates whether a GPS route forms a valid conquest loop according to game rules.
 * Rule 1: Total path distance >= minDistanceMeters (default 100m)
 * Rule 2: Distance from current/end point to start point <= returnToleranceMeters (default 10m)
 * Rule 3: Minimum 4 GPS points required
 */
function checkLoopValidity(points, config = {}) {
  const minDistanceMeters = config.minDistanceMeters || 100;
  const returnToleranceMeters = config.returnToleranceMeters || 10;

  if (!points || points.length < 4) {
    return {
      isValid: false,
      reason: 'Insufficient GPS points collected (minimum 4 points required).',
      pathDistance: calculatePathDistance(points),
      returnDistance: null
    };
  }

  const startPoint = points[0];
  const endPoint = points[points.length - 1];
  const pathDistance = calculatePathDistance(points);
  const returnDistance = haversineDistance(endPoint, startPoint);

  if (pathDistance < minDistanceMeters) {
    return {
      isValid: false,
      reason: `Route distance (${pathDistance.toFixed(1)}m) is less than minimum loop requirement (${minDistanceMeters}m).`,
      pathDistance,
      returnDistance
    };
  }

  if (returnDistance > returnToleranceMeters) {
    return {
      isValid: false,
      reason: `Current position is ${returnDistance.toFixed(1)}m from start point (must return within ${returnToleranceMeters}m).`,
      pathDistance,
      returnDistance
    };
  }

  return {
    isValid: true,
    reason: 'Valid loop completed!',
    pathDistance,
    returnDistance
  };
}

/**
 * Approximates polygon area in square meters using spherical geometry.
 * coordinates format: [[lng, lat], [lng, lat], ...]
 */
function calculatePolygonAreaMeters(coordinates) {
  if (!coordinates || coordinates.length < 3) return 0;
  
  let area = 0;
  const numPoints = coordinates.length;

  for (let i = 0; i < numPoints; i++) {
    const p1 = coordinates[i];
    const p2 = coordinates[(i + 1) % numPoints];

    const lon1 = p1[0] * (Math.PI / 180);
    const lat1 = p1[1] * (Math.PI / 180);
    const lon2 = p2[0] * (Math.PI / 180);
    const lat2 = p2[1] * (Math.PI / 180);

    area += (lon2 - lon1) * (2 + Math.sin(lat1) + Math.sin(lat2));
  }

  area = (Math.abs(area) * EARTH_RADIUS_M * EARTH_RADIUS_M) / 2;
  return area; // Square meters
}

/**
 * Converts a valid GPS route into a closed GeoJSON Polygon structure.
 */
function createClosedPolygon(points) {
  if (!points || points.length < 3) return null;

  // Standardize coordinates to [lng, lat]
  const geojsonCoords = points.map(p => {
    if (Array.isArray(p)) return [p[0], p[1]];
    return [p.lng, p.lat];
  });

  // Ensure polygon ring is closed (first === last)
  const first = geojsonCoords[0];
  const last = geojsonCoords[geojsonCoords.length - 1];

  if (first[0] !== last[0] || first[1] !== last[1]) {
    geojsonCoords.push([first[0], first[1]]);
  }

  const areaMeters = calculatePolygonAreaMeters(geojsonCoords);
  const areaKm2 = areaMeters / 1000000;
  const perimeterMeters = calculatePathDistance(geojsonCoords);

  return {
    type: 'Polygon',
    coordinates: [geojsonCoords],
    areaMeters,
    areaKm2,
    perimeterKm: perimeterMeters / 1000
  };
}

module.exports = {
  haversineDistance,
  calculatePathDistance,
  checkLoopValidity,
  calculatePolygonAreaMeters,
  createClosedPolygon
};
