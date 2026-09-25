import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/track_point.dart';
import '../services/map_service.dart';

class RouteMap extends StatefulWidget {
  const RouteMap({
    super.key,
    required this.points,
    this.currentPosition,
    this.followCurrent = true,
    this.height,
  });

  final List<TrackPoint> points;
  final LatLng? currentPosition;
  final bool followCurrent;
  final double? height;

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  final MapController _controller = MapController();
  bool _initialFitDone = false;

  LatLng get _fallbackCenter {
    if (widget.currentPosition != null) return widget.currentPosition!;
    if (widget.points.isNotEmpty) {
      return LatLng(widget.points.first.latitude, widget.points.first.longitude);
    }
    return const LatLng(30.0444, 31.2357);
  }

  @override
  void didUpdateWidget(covariant RouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.points.length > oldWidget.points.length && widget.followCurrent && widget.currentPosition != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.move(widget.currentPosition!, 16);
      });
    }
  }

  void _fit() {
    if (_initialFitDone || widget.points.length < 2) return;
    final bounds = LatLngBounds.fromPoints(
      widget.points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _controller.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
      );
      _initialFitDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    _fit();
    final route = widget.points.map((p) => LatLng(p.latitude, p.longitude)).toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: widget.height ?? 360,
        child: FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: _fallbackCenter,
            initialZoom: route.length < 2 ? 14 : 15,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
          ),
          children: [
            TileLayer(
              urlTemplate: MapService.tileUrl,
              userAgentPackageName: MapService.userAgent,
            ),
            if (route.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: route,
                    strokeWidth: 5,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            if (widget.currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.currentPosition!,
                    width: 30,
                    height: 30,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
                      ),
                    ),
                  ),
                ],
              ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(MapService.attribution),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
