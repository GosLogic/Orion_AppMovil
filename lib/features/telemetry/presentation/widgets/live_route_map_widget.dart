import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:orion_app/core/theme/orion_colors.dart';
import 'package:orion_app/features/telemetry/domain/entities/vehicle_position.dart';

/// Mapa real con calles (OSM) en modo navegación estilo Waze.
class LiveRouteMapWidget extends StatefulWidget {
  const LiveRouteMapWidget({
    super.key,
    required this.isTracking,
    required this.positionListenable,
    this.isSyncing = false,
    this.pendingCount = 0,
  });

  final bool isTracking;
  final ValueListenable<VehiclePosition?> positionListenable;
  final bool isSyncing;
  final int pendingCount;

  @override
  State<LiveRouteMapWidget> createState() => _LiveRouteMapWidgetState();
}

class _LiveRouteMapWidgetState extends State<LiveRouteMapWidget>
    with TickerProviderStateMixin {
  static const _defaultCenter = LatLng(-12.104, -76.963);
  static const _navZoom = 17.0;
  static const _minZoom = 12.0;
  static const _maxZoom = 20.0;
  static const _movingThresholdKmh = 2.0;

  final _mapController = MapController();

  late final AnimationController _pulseController;
  late final AnimationController _cameraAnim;
  late final Ticker _drTicker;

  LatLng _displayCenter = _defaultCenter;
  double _displayHeading = 0;
  double _speedKmh = 0;
  double _zoomLevel = _navZoom - 1;
  bool _hasFix = false;
  bool _mapReady = false;

  LatLng _animFrom = _defaultCenter;
  LatLng _animTo = _defaultCenter;
  double _animHeadingFrom = 0;
  double _animHeadingTo = 0;

  final List<LatLng> _trail = [];
  DateTime? _drLastTick;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _cameraAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..addListener(_onCameraAnimTick);

    _drTicker = createTicker(_onDeadReckoningTick);
    widget.positionListenable.addListener(_onGpsUpdate);
    _bootstrapLocation();
    _onGpsUpdate();
  }

  Future<void> _bootstrapLocation() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null && mounted && !_hasFix) {
        setState(() {
          _displayCenter = LatLng(last.latitude, last.longitude);
          _hasFix = true;
        });
        _applyCamera();
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(LiveRouteMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isTracking != widget.isTracking) {
      _syncDeadReckoning();
    }
  }

  void _onGpsUpdate() {
    final pos = widget.positionListenable.value;
    if (pos == null) {
      if (!widget.isTracking) {
        setState(() {
          _speedKmh = 0;
          _hasFix = false;
        });
      }
      _syncDeadReckoning();
      return;
    }

    final target = LatLng(pos.latitude, pos.longitude);
    final isFirstFix = !_hasFix;

    if (_hasFix && _trail.isNotEmpty) {
      final last = _trail.last;
      if (last.latitude != target.latitude || last.longitude != target.longitude) {
        _trail.add(target);
        if (_trail.length > 300) _trail.removeAt(0);
      }
    } else {
      _trail.add(target);
    }

    _animFrom = _displayCenter;
    _animTo = target;
    _animHeadingFrom = _displayHeading;
    _animHeadingTo = pos.heading.toDouble();
    _speedKmh = pos.speedKmh;
    _hasFix = true;

    if (isFirstFix) {
      _displayCenter = target;
      _displayHeading = _animHeadingTo;
      _applyCamera();
      setState(() {});
    } else {
      _cameraAnim.forward(from: 0);
    }

    _syncDeadReckoning();
    setState(() {});
  }

  void _onCameraAnimTick() {
    final t = Curves.easeInOutCubic.transform(_cameraAnim.value);
    _displayCenter = LatLng(
      _lerp(_animFrom.latitude, _animTo.latitude, t),
      _lerp(_animFrom.longitude, _animTo.longitude, t),
    );
    _displayHeading = _lerpAngle(_animHeadingFrom, _animHeadingTo, t);
    _applyCamera();
    setState(() {});
  }

  void _onDeadReckoningTick(Duration elapsed) {
    if (!widget.isTracking || _speedKmh < _movingThresholdKmh || !_hasFix) {
      return;
    }

    final now = DateTime.now();
    final dt = _drLastTick == null
        ? 1 / 60
        : now.difference(_drLastTick!).inMicroseconds / 1e6;
    _drLastTick = now;

    if (_cameraAnim.isAnimating) return;

    final meters = (_speedKmh / 3.6) * dt;
    _displayCenter = _offsetByHeading(_displayCenter, _displayHeading, meters);
    _applyCamera();
    setState(() {});
  }

  void _syncDeadReckoning() {
    final active = widget.isTracking && _speedKmh >= _movingThresholdKmh;
    if (active && !_drTicker.isTicking) {
      _drLastTick = DateTime.now();
      _drTicker.start();
    } else if (!active && _drTicker.isTicking) {
      _drTicker.stop();
    }
  }

  void _applyCamera({bool preserveZoom = true}) {
    if (!_mapReady) return;

    if (preserveZoom) {
      _zoomLevel = _mapController.camera.zoom.clamp(_minZoom, _maxZoom);
    }

    final rotation = widget.isTracking && _speedKmh >= _movingThresholdKmh
        ? -_displayHeading
        : 0.0;

    _mapController.moveAndRotate(
      _displayCenter,
      _zoomLevel.clamp(_minZoom, _maxZoom),
      rotation,
    );
  }

  void _zoomBy(double delta) {
    if (!_mapReady) return;
    setState(() {
      _zoomLevel = (_mapController.camera.zoom + delta)
          .clamp(_minZoom, _maxZoom);
    });
    _applyCamera(preserveZoom: false);
  }

  void _resetNavZoom() {
    if (!_mapReady) return;
    setState(() {
      _zoomLevel = _speedKmh >= _movingThresholdKmh ? _navZoom : _navZoom - 1;
    });
    _applyCamera(preserveZoom: false);
  }

  void _onMapEvent(MapEvent event) {
    if (!_mapReady) return;
    if (event is MapEventMove || event is MapEventRotate) {
      _zoomLevel = _mapController.camera.zoom.clamp(_minZoom, _maxZoom);
    }
  }

  LatLng _offsetByHeading(LatLng origin, double headingDeg, double meters) {
    const earthRadius = 6378137.0;
    final rad = headingDeg * math.pi / 180;
    final dLat = meters * math.cos(rad) / earthRadius * (180 / math.pi);
    final dLng = meters *
        math.sin(rad) /
        (earthRadius * math.cos(origin.latitude * math.pi / 180)) *
        (180 / math.pi);
    return LatLng(origin.latitude + dLat, origin.longitude + dLng);
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  double _lerpAngle(double from, double to, double t) {
    var delta = (to - from) % 360;
    if (delta > 180) delta -= 360;
    if (delta < -180) delta += 360;
    return from + delta * t;
  }

  @override
  void dispose() {
    widget.positionListenable.removeListener(_onGpsUpdate);
    _drTicker.dispose();
    _cameraAnim.dispose();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMoving = widget.isTracking && _speedKmh >= _movingThresholdKmh;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 1.05,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _displayCenter,
                initialZoom: _zoomLevel,
                minZoom: _minZoom,
                maxZoom: _maxZoom,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.pinchZoom |
                      InteractiveFlag.doubleTapZoom |
                      InteractiveFlag.doubleTapDragZoom,
                ),
                onMapEvent: _onMapEvent,
                onMapReady: () {
                  _mapReady = true;
                  _applyCamera();
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.orion.orion_app',
                  maxZoom: 20,
                ),
                if (_trail.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: List<LatLng>.from(_trail),
                        color: OrionColors.primary.withValues(alpha: 0.85),
                        strokeWidth: 6,
                        borderColor: Colors.white,
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
              ],
            ),
            if (!widget.isTracking || !_hasFix)
              ColoredBox(
                color: Colors.black.withValues(alpha: 0.25),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      !widget.isTracking
                          ? 'Inicia jornada para ver el mapa en vivo'
                          : 'Obteniendo tu ubicación…',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: OrionColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.isTracking && _hasFix)
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _GpsPulsePainter(
                        progress: _pulseController.value,
                      ),
                    );
                  },
                ),
              ),
            if (widget.isTracking && _hasFix)
              IgnorePointer(
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -6),
                    child: _NavigationArrow(isMoving: isMoving),
                  ),
                ),
              ),
            if (_hasFix)
              Positioned(
                right: 12,
                bottom: 72,
                child: _ZoomControls(
                  zoom: _zoomLevel,
                  minZoom: _minZoom,
                  maxZoom: _maxZoom,
                  onZoomIn: () => _zoomBy(1),
                  onZoomOut: () => _zoomBy(-1),
                  onReset: _resetNavZoom,
                ),
              ),
            Positioned(
              top: 14,
              left: 14,
              child: _MapBadge(
                icon: isMoving
                    ? Icons.navigation_rounded
                    : Icons.location_on_outlined,
                label: !widget.isTracking
                    ? 'Detenido'
                    : isMoving
                        ? 'En ruta'
                        : 'En espera',
                color: widget.isTracking
                    ? (isMoving ? OrionColors.accent : OrionColors.primaryLight)
                    : OrionColors.textMuted,
              ),
            ),
            if (widget.isTracking && _hasFix)
              Positioned(
                top: 14,
                right: 14,
                child: _MapBadge(
                  icon: Icons.speed_rounded,
                  label: '${_speedKmh.round()} km/h',
                  color: OrionColors.primary,
                ),
              ),
            Positioned(
              bottom: 14,
              left: 14,
              right: 14,
              child: _BottomStatusBar(
                isTracking: widget.isTracking,
                isMoving: isMoving,
                isSyncing: widget.isSyncing,
                hasFix: _hasFix,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.zoom,
    required this.minZoom,
    required this.maxZoom,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final double zoom;
  final double minZoom;
  final double maxZoom;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final canZoomIn = zoom < maxZoom - 0.1;
    final canZoomOut = zoom > minZoom + 0.1;

    return Material(
      color: Colors.white.withValues(alpha: 0.94),
      elevation: 3,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZoomButton(
            icon: Icons.add_rounded,
            tooltip: 'Acercar',
            enabled: canZoomIn,
            onPressed: onZoomIn,
          ),
          Container(height: 1, color: Colors.grey.shade200),
          _ZoomButton(
            icon: Icons.remove_rounded,
            tooltip: 'Alejar',
            enabled: canZoomOut,
            onPressed: onZoomOut,
          ),
          Container(height: 1, color: Colors.grey.shade200),
          _ZoomButton(
            icon: Icons.my_location_rounded,
            tooltip: 'Zoom navegación',
            enabled: true,
            onPressed: onReset,
          ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.tooltip,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onPressed : null,
      tooltip: tooltip,
      icon: Icon(
        icon,
        size: 22,
        color: enabled ? OrionColors.primary : OrionColors.textMuted,
      ),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}

class _NavigationArrow extends StatelessWidget {
  const _NavigationArrow({required this.isMoving});

  final bool isMoving;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: isMoving ? OrionColors.primary : OrionColors.primaryLight,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: OrionColors.primary.withValues(alpha: 0.4),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.navigation_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 14,
          height: 6,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      ],
    );
  }
}

class _MapBadge extends StatelessWidget {
  const _MapBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomStatusBar extends StatelessWidget {
  const _BottomStatusBar({
    required this.isTracking,
    required this.isMoving,
    required this.isSyncing,
    required this.hasFix,
  });

  final bool isTracking;
  final bool isMoving;
  final bool isSyncing;
  final bool hasFix;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isTracking ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
            size: 18,
            color: isTracking ? OrionColors.accent : OrionColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              !isTracking
                  ? 'Mapa listo · inicia jornada'
                  : !hasFix
                      ? 'Buscando señal GPS…'
                      : isSyncing
                          ? 'Enviando ubicación al operador…'
                          : isMoving
                              ? 'Navegando · mapa real siguiendo tu movimiento'
                              : 'Mapa en tu posición · listo para avanzar',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GpsPulsePainter extends CustomPainter {
  _GpsPulsePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 6);
    for (var i = 0; i < 2; i++) {
      final t = (progress + i * 0.5) % 1.0;
      final radius = 26 + t * 48;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = OrionColors.accent.withValues(alpha: (1 - t) * 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GpsPulsePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
