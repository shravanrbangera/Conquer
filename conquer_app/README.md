# CONQUER Mobile Application (`conquer_app`)

Flutter-based GPS adventure fitness game featuring real-time map rendering, interactive territory polygons, and live route tracking.

---

## Map Tile Provider Configuration

For local development and testing, this app is configured to use **OpenStreetMap Standard tiles**:
- **URL**: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
- **Attribution**: `© OpenStreetMap contributors`
- **User-Agent**: `com.conquer.conquer_app`

### OpenStreetMap Tile Usage Policy Notice
This application adheres to the [OpenStreetMap Foundation Tile Usage Policy](https://operations.osmfoundation.org/policies/tiles/):
- **No bulk downloading** or scraping of tiles.
- **No offline prefetching** or caching beyond standard HTTP client caches.
- For high-volume production deployments, configure a dedicated commercial tile provider (Mapbox, Stadia Maps) or a self-hosted vector tile server (TileServer GL / Protomaps).

---

## Running the App

```bash
flutter pub get
flutter run -d chrome --web-port 8080
```

### Running Tests
```bash
flutter test
flutter analyze
```
