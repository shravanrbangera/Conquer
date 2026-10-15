# CONQUER — Real-World GPS Territory Fitness Game

CONQUER turns real-world outdoor walks, runs, and fitness activities into a multiplayer tactical territory conquest game. Walk a closed loop over 100 metres in the real world to claim that land, expand your empire, and slice into rival commanders' sectors.

---

## Architecture Overview

- **Flutter Mobile App (`conquer_app`)**: Interactive `flutter_map` with real-time GPS tracking, territory MultiPolygon overlays, Battle Log event feed, and tactical cyberpunk HUD.
- **Node.js Geospatial Engine (`backend`)**: Express REST API utilizing Turf.js for polygon validation, loop closure verification, anti-cheat detection, polygon differences (slicing), and concurrency-safe territory claims.

---

## Map Tile Provider & OpenStreetMap Policy

### Development & MVP Tile Configuration
For local development, testing, and MVP usage, CONQUER uses **OpenStreetMap Standard tiles** without requiring any paid API keys (such as Google Maps or CARTO).

- **Tile URL Template**: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
- **Attribution**: `© OpenStreetMap contributors` (visibly rendered on the map and attribution sheet)
- **User-Agent Identifier**: `com.conquer.conquer_app` (identifies client traffic to comply with OSM policies)
- **API Keys**: **None required**. No CARTO watermark (`API KEY REQUIRED`) or billing setup needed.

---

### OpenStreetMap Tile Usage Policy Review

OpenStreetMap tile servers (`tile.openstreetmap.org`) are operated entirely on volunteer donations and community infrastructure. To maintain access and respect the community, the application strictly adheres to the [OpenStreetMap Tile Usage Policy](https://operations.osmfoundation.org/policies/tiles/):

1. **Strictly No Bulk Tile Downloading**:
   - The application **does not** implement bulk tile downloads, tile scrapers, or programmatic area downloads.
2. **Strictly No Offline Prefetching**:
   - Systematic caching or prefetching of bounding boxes is prohibited. Tiles are fetched on-demand only as the user actively views or navigates the map.
3. **Valid User-Agent**:
   - All tile requests carry a clear, unique `userAgentPackageName` (`com.conquer.conquer_app`).
4. **Caching**:
   - Standard HTTP caching headers sent by the OSM tile servers are respected.
5. **Connection Limits**:
   - Threading is bounded to prevent excessive concurrent socket connections.

---

### Production Tile-Provider Requirements

Standard OSM tile servers (`tile.openstreetmap.org`) are **not intended for production mobile apps with high traffic**. Prior to publishing CONQUER to the Google Play Store or Apple App Store, the tile layer must transition to a dedicated production tile provider:

1. **Option A: Self-Hosted Vector/Raster Server (Recommended for cost control)**
   - **Protomaps (PMTiles)** or **TileServer GL** with OpenMapTiles data.
   - Hosted on Cloudflare R2, AWS S3, or a dedicated VPS.
   - Supports custom dark-matter / cyberpunk styling with near-zero ongoing tile fees.

2. **Option B: Commercial Vector/Raster Providers (Recommended for rapid launch)**
   - **Stadia Maps**: Offers Alidade Smooth Dark and custom styles with SLA and high rate limits.
   - **Mapbox**: Full vector map SDK with custom studio themes and dark mode rendering.
   - **MapTiler**: Cloud-hosted OpenStreetMap tiles with generous tiers.

3. **Option C: CARTO with Registered API Key**
   - If restoring CARTO basemaps (Dark Matter / Voyager), obtain an authorized API key from [carto.com](https://carto.com) and append `?api_key=YOUR_KEY` to the URL template in `lib/core/constants/map_tile_providers.dart`.

---

## Quick Start & Testing

### 1. Start the Backend Territory Server
```bash
cd backend
npm install
node server.js
```
The server will start on `http://localhost:5000`.

### 2. Run the Flutter App
```bash
cd conquer_app
flutter pub get
flutter run -d chrome --web-port 8080
# or for Windows desktop:
# flutter run -d windows
```

### 3. Testing the Map & Conquest Flow
1. **Interactive Map**:
   - The map loads OpenStreetMap standard tiles centered on your GPS position or default staging coordinates.
   - Use the floating layer button (bottom right) to switch between **OpenStreetMap Standard**, **CyclOSM Tactical**, and **OpenTopoMap Terrain**.
   - Notice the visible `© OpenStreetMap contributors` attribution badge at the bottom-left corner.
2. **GPS Tracking & Simulation**:
   - Tap **START CONQUEST** on the bottom navigation bar.
   - Tap **SIM LOOP** to simulate a valid $>100\text{m}$ closed loop path.
   - Tap **CLAIM** to submit the loop to the backend.
   - The **TERRITORY SECURED** screen will display your newly conquered area, stolen enemy territory, XP, and unlocked achievements.
3. **Multi-User Switching**:
   - Tap the top-left commander avatar to toggle between **SHRAVAN** (Vanguard Blue) and **RAHUL** (Shadow Syndicate Red).

---

## Testing & Quality Assurance

- **Backend Geospatial Tests**: `cd backend && npm test` (17/17 passing)
- **Flutter Test Suite**: `cd conquer_app && flutter test` (28/28 passing)
- **Static Analysis**: `cd conquer_app && flutter analyze` (0 issues)
