class MapTileProviderConfig {
  final String id;
  final String name;
  final String urlTemplate;
  final List<String> subdomains;
  final String attribution;
  final int maxZoom;
  final String userAgentPackageName;

  const MapTileProviderConfig({
    required this.id,
    required this.name,
    required this.urlTemplate,
    this.subdomains = const [],
    required this.attribution,
    this.maxZoom = 19,
    this.userAgentPackageName = 'com.conquer.conquer_app',
  });
}

class MapTileProviders {
  MapTileProviders._();

  /// Primary: OpenStreetMap Standard (Community-hosted, no API key required)
  /// Compliant with OpenStreetMap Tile Usage Policy for dev/testing.
  static const MapTileProviderConfig openStreetMap = MapTileProviderConfig(
    id: 'osm_standard',
    name: 'OpenStreetMap Standard',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    subdomains: [],
    attribution: '© OpenStreetMap contributors',
    maxZoom: 19,
    userAgentPackageName: 'com.conquer.conquer_app',
  );

  /// Secondary: CyclOSM (Pedestrian/Bicycle fitness tactical map style)
  static const MapTileProviderConfig cyclOSM = MapTileProviderConfig(
    id: 'cyclosm',
    name: 'CyclOSM Tactical',
    urlTemplate: 'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
    subdomains: ['a', 'b', 'c'],
    attribution: 'Map data: © OpenStreetMap contributors | Style: CyclOSM',
    maxZoom: 18,
    userAgentPackageName: 'com.conquer.conquer_app',
  );

  /// Tertiary: OpenTopoMap (Topographic terrain contour style)
  static const MapTileProviderConfig openTopo = MapTileProviderConfig(
    id: 'open_topo',
    name: 'OpenTopoMap Terrain',
    urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
    subdomains: ['a', 'b', 'c'],
    attribution: 'Map data: © OpenStreetMap contributors, SRTM | Style: OpenTopoMap',
    maxZoom: 17,
    userAgentPackageName: 'com.conquer.conquer_app',
  );

  /// Default tile provider for CONQUER MVP: OpenStreetMap Standard
  static const MapTileProviderConfig defaultProvider = openStreetMap;

  /// Retained for backwards compatibility, redirected to OpenStreetMap to prevent CARTO watermark
  @Deprecated('Use openStreetMap. CARTO basemaps require a paid API key.')
  static const MapTileProviderConfig cartoDark = openStreetMap;

  /// Retained for backwards compatibility, redirected to CyclOSM
  @Deprecated('Use cyclOSM or openStreetMap. CARTO basemaps require a paid API key.')
  static const MapTileProviderConfig cartoVoyager = cyclOSM;

  /// All available zero-API-key tile providers
  static const List<MapTileProviderConfig> all = [
    openStreetMap,
    cyclOSM,
    openTopo,
  ];
}
