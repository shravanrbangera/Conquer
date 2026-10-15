import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/location_service.dart';
import '../../../data/models/territory_model.dart';
import '../../../providers/location_provider.dart';
import '../../../providers/map_provider.dart';

class RealInteractiveMap extends ConsumerStatefulWidget {
  final List<TerritoryModel> territories;
  final List<MapCoordinate> activeRoute;
  final Function(TerritoryModel)? onTerritoryTap;

  const RealInteractiveMap({
    super.key,
    required this.territories,
    this.activeRoute = const [],
    this.onTerritoryTap,
  });

  @override
  ConsumerState<RealInteractiveMap> createState() => _RealInteractiveMapState();
}

class _RealInteractiveMapState extends ConsumerState<RealInteractiveMap>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;
  bool _hasTileError = false;

  // Fallback initial coordinate anchor (used only before first GPS fix is acquired)
  static const LatLng _fallbackCenter = LatLng(13.3440, 74.7440);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  void _recenterOnPlayer(LatLng? playerLocation) {
    if (playerLocation != null) {
      _mapController.move(playerLocation, 16.5);
    } else {
      ref.read(locationProvider.notifier).refreshLocation();
    }
  }

  LatLng _computeCentroid(List<MapCoordinate> points) {
    if (points.isEmpty) return _fallbackCenter;
    double latSum = 0;
    double lngSum = 0;
    for (final p in points) {
      latSum += p.lat;
      lngSum += p.lng;
    }
    return LatLng(latSum / points.length, lngSum / points.length);
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final mapState = ref.watch(mapProvider);
    final playerLatLng = locationState.latLng;

    // Convert active route coordinates to LatLng
    final routeLatLngs = widget.activeRoute
        .map((coord) => LatLng(coord.lat, coord.lng))
        .toList();

    return Stack(
      children: [
        // 1. REAL FLUTTER_MAP WITH CONFIGURABLE TILE PROVIDER
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: playerLatLng ??
                (widget.territories.isNotEmpty
                    ? _computeCentroid(widget.territories.first.polygonPoints)
                    : _fallbackCenter),
            initialZoom: 16.0,
            minZoom: 3.0,
            maxZoom: 19.5,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // A. Configurable OpenStreetMap-compatible Tile Layer
            TileLayer(
              urlTemplate: mapState.currentProvider.urlTemplate,
              subdomains: mapState.currentProvider.subdomains,
              userAgentPackageName:
                  mapState.currentProvider.userAgentPackageName,
              maxZoom: mapState.currentProvider.maxZoom.toDouble(),
              errorTileCallback: (tile, error, stackTrace) {
                if (mounted && !_hasTileError) {
                  setState(() {
                    _hasTileError = true;
                  });
                }
              },
            ),

            // B. Territory Polygon Overlays (Player Blue & Hostile Crimson)
            // B. Territory Polygon Overlays (Supports Polygon & MultiPolygon)
            PolygonLayer(
              polygons: [
                for (final territory in widget.territories)
                  for (final ring in territory.allRings)
                    Polygon(
                      points: ring.map((p) => LatLng(p.lat, p.lng)).toList(),
                      color: territory.color.withValues(
                        alpha: territory.underAttack ? 0.45 : 0.28,
                      ),
                      borderColor: territory.underAttack
                          ? AppColors.neonCrimson
                          : territory.color,
                      borderStrokeWidth: territory.underAttack ? 3.0 : 2.0,
                    ),
              ],
            ),

            // C. Active Conquest Route Polyline
            if (routeLatLngs.isNotEmpty) ...[
              // Glow Polyline Backing
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routeLatLngs,
                    color: AppColors.neonEmerald.withValues(alpha: 0.35),
                    strokeWidth: 8.0,
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                ],
              ),
              // Crisp Core Polyline
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routeLatLngs,
                    color: AppColors.neonEmerald,
                    strokeWidth: 3.5,
                    strokeCap: StrokeCap.round,
                    strokeJoin: StrokeJoin.round,
                  ),
                ],
              ),
            ],

            // D. Markers: Start, Finish, Centroids, and Live Current Location
            MarkerLayer(
              markers: [
                // Territory Centroid Label Markers
                for (final territory in widget.territories)
                  Marker(
                    point: _computeCentroid(territory.polygonPoints),
                    width: 140,
                    height: 40,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: territory.underAttack
                                ? AppColors.neonCrimson
                                : territory.color,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${territory.name}\n${territory.areaKm2} km²',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: territory.underAttack
                                ? AppColors.neonCrimson
                                : Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Start Marker (First waypoint of active conquest)
                if (routeLatLngs.isNotEmpty)
                  Marker(
                    point: routeLatLngs.first,
                    width: 54,
                    height: 54,
                    alignment: Alignment.topCenter,
                    child: _buildStartMarker(),
                  ),

                // Finish / Close-Loop Target Marker
                if (routeLatLngs.length >= 2)
                  Marker(
                    point: routeLatLngs.last,
                    width: 54,
                    height: 54,
                    alignment: Alignment.topCenter,
                    child: _buildFinishMarker(),
                  ),

                // Real-time Current GPS Location Marker
                if (playerLatLng != null)
                  Marker(
                    point: playerLatLng,
                    width: 50,
                    height: 50,
                    child: _buildPlayerLocationMarker(),
                  ),
              ],
            ),

            // E. Required Map Attribution Widget
            RichAttributionWidget(
              animationConfig: const ScaleRAWA(),
              attributions: [
                TextSourceAttribution(
                  mapState.currentProvider.attribution,
                  textStyle: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),

        // 2. TILE LOADING ERROR BANNER
        if (_hasTileError)
          Positioned(
            top: 64,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bgSurface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.neonCrimson, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonCrimson.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      color: AppColors.neonCrimson, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'OpenStreetMap tiles could not load. Check network connection.',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _hasTileError = false;
                      });
                      _mapController.move(
                          _mapController.camera.center, _mapController.camera.zoom);
                    },
                    child: const Text('RETRY',
                        style: TextStyle(color: AppColors.neonCyan, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ),

        // 3. LOCATION PERMISSION & ERROR STATE BANNER
        if (locationState.permissionState != LocationPermissionState.granted)
          Positioned(
            top: _hasTileError ? 120 : 100,
            left: 16,
            right: 16,
            child: _buildLocationStateBanner(locationState),
          ),

        // 4. VISIBLE MAP ATTRIBUTION CHIP (OSM Attribution Policy Compliant)
        Positioned(
          left: 12,
          bottom: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.borderSubtle, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.public, size: 11, color: AppColors.neonCyan),
                const SizedBox(width: 5),
                Text(
                  mapState.currentProvider.attribution,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. FLOATING MAP CONTROLS (Right-hand side)
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tile Provider Switcher
              _buildControlButton(
                icon: Icons.layers_outlined,
                tooltip:
                    'Active Provider: ${mapState.currentProvider.name}',
                onTap: () {
                  ref.read(mapProvider.notifier).toggleNextProvider();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '🗺️ Tile Provider: ${ref.read(mapProvider).currentProvider.name}'),
                      duration: const Duration(seconds: 1),
                      backgroundColor: AppColors.bgSurface,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              // Zoom In Button
              _buildControlButton(
                icon: Icons.add,
                tooltip: 'Zoom In',
                onTap: _zoomIn,
              ),
              const SizedBox(height: 6),

              // Zoom Out Button
              _buildControlButton(
                icon: Icons.remove,
                tooltip: 'Zoom Out',
                onTap: _zoomOut,
              ),
              const SizedBox(height: 10),

              // Recenter on Player GPS Location
              _buildControlButton(
                icon: playerLatLng != null
                    ? Icons.my_location
                    : Icons.location_searching,
                iconColor: playerLatLng != null
                    ? AppColors.neonCyan
                    : AppColors.neonGold,
                tooltip: 'Center on Current Location',
                onTap: () => _recenterOnPlayer(playerLatLng),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        border: Border.all(
          color: (iconColor ?? AppColors.neonCyan).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor ?? AppColors.neonCyan, size: 20),
        tooltip: tooltip,
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildStartMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.neonEmerald,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'START',
            style: TextStyle(
              color: Colors.black,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Icon(Icons.location_on, color: AppColors.neonEmerald, size: 24),
      ],
    );
  }

  Widget _buildFinishMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.neonGold,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'FINISH',
            style: TextStyle(
              color: Colors.black,
              fontSize: 8,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Icon(Icons.flag_rounded, color: AppColors.neonGold, size: 24),
      ],
    );
  }

  Widget _buildPlayerLocationMarker() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.6);
        final opacity = 1.0 - _pulseController.value;

        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulsing outer radar ring
            Transform.scale(
              scale: scale,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.neonCyan.withValues(alpha: opacity * 0.8),
                    width: 2,
                  ),
                ),
              ),
            ),
            // Glowing core marker
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonCyan,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.neonCyan.withValues(alpha: 0.8),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLocationStateBanner(LocationState locationState) {
    String title;
    String subtitle;
    String actionLabel;
    VoidCallback onAction;
    Color accentColor = AppColors.neonGold;

    switch (locationState.permissionState) {
      case LocationPermissionState.loading:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bgSurface.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.5)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.neonCyan,
                ),
              ),
              SizedBox(width: 10),
              Text(
                '🛰️ Acquiring GPS Satellite Lock...',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        );

      case LocationPermissionState.serviceDisabled:
        title = 'GPS Location Disabled';
        subtitle = 'Turn on device location to trace loops and conquer territory.';
        actionLabel = 'ENABLE GPS';
        accentColor = AppColors.neonGold;
        onAction = () => ref.read(locationProvider.notifier).openLocationService();
        break;

      case LocationPermissionState.denied:
        title = 'Location Permission Required';
        subtitle = 'CONQUER requires GPS access to map your physical routes.';
        actionLabel = 'GRANT';
        accentColor = AppColors.neonCyan;
        onAction = () => ref.read(locationProvider.notifier).refreshLocation();
        break;

      case LocationPermissionState.deniedForever:
        title = 'Location Permission Blocked';
        subtitle = 'GPS permission is permanently denied in system settings.';
        actionLabel = 'SETTINGS';
        accentColor = AppColors.neonCrimson;
        onAction = () => ref.read(locationProvider.notifier).openSettings();
        break;

      case LocationPermissionState.error:
      default:
        title = 'GPS Error';
        subtitle = locationState.errorMessage ?? 'Unable to acquire location.';
        actionLabel = 'RETRY';
        accentColor = AppColors.neonCrimson;
        onAction = () => ref.read(locationProvider.notifier).refreshLocation();
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgSurface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.2),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.location_off_rounded, color: accentColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor.withValues(alpha: 0.2),
              foregroundColor: accentColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(60, 30),
              side: BorderSide(color: accentColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
