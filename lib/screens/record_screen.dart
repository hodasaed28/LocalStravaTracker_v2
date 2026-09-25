import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../models/activity.dart';
import '../services/tracking_service.dart';
import '../widgets/metric_card.dart';
import '../widgets/route_map.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key, required this.tracker, this.autoStart = false});
  final TrackingService tracker;
  final bool autoStart;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  ActivityType _type = ActivityType.run;
  bool _startedAuto = false;
  double _weight = 70;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_startedAuto) {
          _startedAuto = true;
          _start();
        }
      });
    }
  }

  Future<void> _start() async {
    await widget.tracker.start(_type, weightKg: _weight);
    if (!mounted) return;
    if (widget.tracker.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.tracker.errorMessage!)));
    }
  }

  Future<void> _stop() async {
    final activity = await widget.tracker.stop();
    if (!mounted || activity == null) return;
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.tracker,
      builder: (context, _) {
        final position = widget.tracker.currentPosition;
        final current = position == null ? null : LatLng(position.latitude, position.longitude);
        final points = widget.tracker.points;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.tracker.isRecording ? '${widget.tracker.selectedType?.label ?? 'Activity'} recording' : 'Record activity'),
            actions: [
              if (widget.tracker.isRecording)
                IconButton(
                  tooltip: 'Stop',
                  onPressed: _stop,
                  icon: const Icon(Icons.stop_circle_outlined),
                ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                RouteMap(points: points, currentPosition: current, followCurrent: true, height: 390),
                const SizedBox(height: 16),
                if (!widget.tracker.isRecording) _StartCard(onStart: _start, type: _type, weight: _weight, onTypeChanged: (value) => setState(() => _type = value), onWeightChanged: (value) => setState(() => _weight = value)),
                if (widget.tracker.isRecording) ...[
                  Text(
                    widget.tracker.isPaused ? 'Paused' : 'Live tracking',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.65,
                    children: [
                      MetricCard(label: 'Distance', value: (widget.tracker.distanceMeters / 1000).toStringAsFixed(2), unit: 'km', icon: Icons.straighten_rounded),
                      MetricCard(label: 'Duration', value: _duration(widget.tracker.elapsedSeconds), icon: Icons.timer_outlined),
                      MetricCard(label: 'Pace', value: _pace(widget.tracker.averageSpeedMps), unit: '/km', icon: Icons.speed_rounded),
                      MetricCard(label: 'Calories', value: widget.tracker.calories.toStringAsFixed(0), unit: 'kcal', icon: Icons.local_fire_department_outlined),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: widget.tracker.isPaused ? widget.tracker.resume : widget.tracker.pause,
                          icon: Icon(widget.tracker.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                          label: Text(widget.tracker.isPaused ? 'Resume' : 'Pause'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _stop,
                          icon: const Icon(Icons.stop_rounded),
                          label: const Text('Finish'),
                        ),
                      ),
                    ],
                  ),
                  if (widget.tracker.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(widget.tracker.errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                ],
              ],
            ),
          ),
        );
      },
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
    final secondsPerKm = (1000 / speedMps).round();
    final minutes = secondsPerKm ~/ 60;
    final seconds = secondsPerKm % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class _StartCard extends StatelessWidget {
  const _StartCard({required this.onStart, required this.type, required this.weight, required this.onTypeChanged, required this.onWeightChanged});
  final VoidCallback onStart;
  final double weight;
  final ActivityType type;
  final ValueChanged<ActivityType> onTypeChanged;
  final ValueChanged<double> onWeightChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose activity', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ActivityType.values.map((item) => ChoiceChip(label: Text(item.label), selected: item == type, onSelected: (_) => onTypeChanged(item))).toList(),
          ),
          const SizedBox(height: 14),
          Text('Weight (kg)', style: Theme.of(context).textTheme.labelLarge),
          Slider(
            value: weight,
            min: 35,
            max: 150,
            divisions: 115,
            label: '${weight.round()} kg',
            onChanged: (value) {
              onWeightChanged(value);
            },
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(onPressed: onStart, icon: const Icon(Icons.gps_fixed_rounded), label: const Text('Start GPS tracking')),
          ),
          const SizedBox(height: 8),
          Text('GPS must be enabled. Android will show a persistent notification while background tracking is active.', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
