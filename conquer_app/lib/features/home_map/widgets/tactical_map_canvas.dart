import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/territory_model.dart';

enum MapLayerStyle { tactical, satellite }

class TacticalMapCanvas extends StatefulWidget {
  final List<TerritoryModel> territories;
  final List<MapCoordinate> activeRoute;
  final MapCoordinate playerLocation;
  final MapLayerStyle layerStyle;
  final Function(TerritoryModel)? onTerritoryTap;

  const TacticalMapCanvas({
    super.key,
    required this.territories,
    this.activeRoute = const [],
    this.playerLocation = const MapCoordinate(lat: 13.344, lng: 74.744),
    this.layerStyle = MapLayerStyle.tactical,
    this.onTerritoryTap,
  });

  @override
  State<TacticalMapCanvas> createState() => _TacticalMapCanvasState();
}

class _TacticalMapCanvasState extends State<TacticalMapCanvas>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Offset _panOffset = Offset.zero;
  double _zoom = 1.0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleUpdate: (details) {
        setState(() {
          _zoom = (_zoom * details.scale).clamp(0.6, 2.5);
          _panOffset += details.focalPointDelta;
        });
      },
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: _TacticalMapPainter(
                territories: widget.territories,
                activeRoute: widget.activeRoute,
                playerLocation: widget.playerLocation,
                layerStyle: widget.layerStyle,
                panOffset: _panOffset,
                zoom: _zoom,
                pulseValue: _pulseController.value,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TacticalMapPainter extends CustomPainter {
  final List<TerritoryModel> territories;
  final List<MapCoordinate> activeRoute;
  final MapCoordinate playerLocation;
  final MapLayerStyle layerStyle;
  final Offset panOffset;
  final double zoom;
  final double pulseValue;

  _TacticalMapPainter({
    required this.territories,
    required this.activeRoute,
    required this.playerLocation,
    required this.layerStyle,
    required this.panOffset,
    required this.zoom,
    required this.pulseValue,
  });

  // Reference GPS anchor
  static const double refLat = 13.344;
  static const double refLng = 74.744;

  Offset _gpsToScreen(MapCoordinate coord, Size size) {
    final centerX = size.width / 2 + panOffset.dx;
    final centerY = size.height / 2 + panOffset.dy;

    // Scale 1 degree lat/lng to screen pixels
    const double scaleFactor = 35000.0;
    final dx = (coord.lng - refLng) * scaleFactor * zoom;
    final dy = -(coord.lat - refLat) * scaleFactor * zoom;

    return Offset(centerX + dx, centerY + dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background
    final bgPaint = Paint()
      ..color = layerStyle == MapLayerStyle.tactical
          ? const Color(0xFF040814)
          : const Color(0xFF02040A);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final centerX = size.width / 2 + panOffset.dx;
    final centerY = size.height / 2 + panOffset.dy;

    // 2. Tactical Grid Lines
    final gridPaint = Paint()
      ..color = AppColors.neonCyan.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    const double gridSpacing = 60.0;
    final startX = (panOffset.dx % gridSpacing);
    final startY = (panOffset.dy % gridSpacing);

    for (double x = startX; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = startY; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 3. Radar Scanning Circles
    final radarPaint = Paint()
      ..color = AppColors.neonCyan.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final radius in [100.0, 200.0, 320.0]) {
      canvas.drawCircle(Offset(centerX, centerY), radius * zoom, radarPaint);
    }

    // Radar Sweeper Beam
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          AppColors.neonCyan.withValues(alpha: 0.0),
          AppColors.neonCyan.withValues(alpha: 0.12),
        ],
        stops: const [0.85, 1.0],
        transform: GradientRotation(pulseValue * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: Offset(centerX, centerY), radius: 320 * zoom));

    canvas.drawCircle(Offset(centerX, centerY), 320 * zoom, sweepPaint);

    // 4. Draw Territory Polygons
    for (final territory in territories) {
      if (territory.polygonPoints.isEmpty) continue;

      final path = Path();
      final firstPt = _gpsToScreen(territory.polygonPoints.first, size);
      path.moveTo(firstPt.dx, firstPt.dy);

      for (int i = 1; i < territory.polygonPoints.length; i++) {
        final pt = _gpsToScreen(territory.polygonPoints[i], size);
        path.lineTo(pt.dx, pt.dy);
      }
      path.close();

      // Territory Fill
      final fillPaint = Paint()
        ..color = territory.color.withValues(alpha: territory.underAttack ? 0.45 : 0.25)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      // Territory Border with glow
      final borderPaint = Paint()
        ..color = territory.underAttack ? AppColors.neonCrimson : territory.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawPath(path, borderPaint);

      // Territory Label
      final bounds = path.getBounds();
      final textSpan = TextSpan(
        text: '${territory.name}\n${territory.areaKm2} km²',
        style: TextStyle(
          color: territory.color,
          fontSize: 10 * zoom.clamp(0.8, 1.3),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          bounds.center.dx - textPainter.width / 2,
          bounds.center.dy - textPainter.height / 2,
        ),
      );
    }

    // 5. Draw Active Conquest Route Polyline
    if (activeRoute.isNotEmpty) {
      final routePath = Path();
      final firstRoutePt = _gpsToScreen(activeRoute.first, size);
      routePath.moveTo(firstRoutePt.dx, firstRoutePt.dy);

      for (int i = 1; i < activeRoute.length; i++) {
        final pt = _gpsToScreen(activeRoute[i], size);
        routePath.lineTo(pt.dx, pt.dy);
      }

      // Outer glow line
      final glowLinePaint = Paint()
        ..color = AppColors.neonEmerald.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(routePath, glowLinePaint);

      // Core crisp polyline
      final coreLinePaint = Paint()
        ..color = AppColors.neonEmerald
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(routePath, coreLinePaint);

      // Waypoint dots
      final dotPaint = Paint()..color = Colors.white;
      for (final pt in activeRoute) {
        final screenPt = _gpsToScreen(pt, size);
        canvas.drawCircle(screenPt, 3.5, dotPaint);
      }
    }

    // 6. Draw Player GPS Marker
    final playerScreenPt = _gpsToScreen(playerLocation, size);

    // Pulsing Outer Rings
    final pulseRadius = (16.0 + (pulseValue * 22.0)) * zoom;
    final pulseRingPaint = Paint()
      ..color = AppColors.neonCyan.withValues(alpha: (1.0 - pulseValue) * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(playerScreenPt, pulseRadius, pulseRingPaint);

    // Core Player Pin
    final playerGlowPaint = Paint()
      ..color = AppColors.neonCyan.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(playerScreenPt, 10 * zoom, playerGlowPaint);

    final playerCorePaint = Paint()..color = AppColors.neonCyan;
    canvas.drawCircle(playerScreenPt, 7 * zoom, playerCorePaint);

    final playerCenterDotPaint = Paint()..color = Colors.black;
    canvas.drawCircle(playerScreenPt, 3 * zoom, playerCenterDotPaint);
  }

  @override
  bool shouldRepaint(covariant _TacticalMapPainter oldDelegate) {
    return oldDelegate.panOffset != panOffset ||
        oldDelegate.zoom != zoom ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.activeRoute != activeRoute ||
        oldDelegate.layerStyle != layerStyle ||
        oldDelegate.territories != territories;
  }
}
