import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/activity.dart';
import '../models/track_point.dart';
import '../services/activity_database.dart';
import '../services/gpx_service.dart';
import '../widgets/metric_card.dart';
import '../widgets/route_map.dart';

class ActivityDetailScreen extends StatefulWidget {
  const ActivityDetailScreen({super.key, required this.activity});
  final Activity activity;

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  List<TrackPoint> _points = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final points = widget.activity.id == null ? <TrackPoint>[] : await ActivityDatabase.instance.getPoints(widget.activity.id!);
    if (!mounted) return;
    setState(() => _points = points);
  }

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      await GpxService.shareGpx(widget.activity, _points);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete activity?'),
        content: const Text('This removes the activity and all stored GPS points from this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || widget.activity.id == null) return;
    await ActivityDatabase.instance.deleteActivity(widget.activity.id!);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.activity;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [
          IconButton(onPressed: _busy ? null : _share, icon: const Icon(Icons.ios_share_rounded)),
          IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          RouteMap(points: _points, height: 360, followCurrent: false),
          const SizedBox(height: 18),
          Text(a.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(DateFormat('EEE, d MMM yyyy • HH:mm').format(a.startedAt)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.65,
            children: [
              MetricCard(label: 'Distance', value: (a.distanceMeters / 1000).toStringAsFixed(2), unit: 'km', icon: Icons.straighten_rounded),
              MetricCard(label: 'Duration', value: _duration(a.durationSeconds), icon: Icons.timer_outlined),
              MetricCard(label: 'Pace', value: _pace(a.avgSpeedMps), unit: '/km', icon: Icons.speed_rounded),
              MetricCard(label: 'Elevation', value: a.elevationGainMeters.toStringAsFixed(0), unit: 'm', icon: Icons.terrain_rounded),
            ],
          ),
          const SizedBox(height: 12),
          MetricCard(label: 'Calories', value: a.calories.toStringAsFixed(0), unit: 'kcal', icon: Icons.local_fire_department_outlined),
          const SizedBox(height: 18),
          if (_points.isNotEmpty)
            Text('${_points.length} GPS points recorded', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  String _duration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  String _pace(double speedMps) {
    if (speedMps <= 0) return '--:--';
    final total = (1000 / speedMps).round();
    return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
  }
}
