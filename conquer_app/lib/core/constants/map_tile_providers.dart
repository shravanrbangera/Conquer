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

  /// CartoDB Dark Matter (Cyberpunk theme compliant)
  static const MapTileProviderConfig cartoDark = MapTileProviderConfig(
    id: 'carto_dark',
    name: 'CartoDB Dark Matter',
    urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
    subdomains: ['a', 'b', 'c', 'd'],
    attribution: '© OpenStreetMap contributors, © CARTO',
    maxZoom: 20,
  );

  /// OpenStreetMap Standard
  static const MapTileProviderConfig openStreetMap = MapTileProviderConfig(
    id: 'osm_standard',
    name: 'OpenStreetMap Standard',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    subdomains: [],
    attribution: '© OpenStreetMap contributors',
    maxZoom: 19,
  );

  /// CartoDB Voyager (Tactical Recon light mode)
  static const MapTileProviderConfig cartoVoyager = MapTileProviderConfig(
    id: 'carto_voyager',
    name: 'Tactical Recon (Voyager)',
    urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
    subdomains: ['a', 'b', 'c', 'd'],
    attribution: '© OpenStreetMap contributors, © CARTO',
    maxZoom: 19,
  );

  static const List<MapTileProviderConfig> all = [
    cartoDark,
    openStreetMap,
    cartoVoyager,
  ];
}
