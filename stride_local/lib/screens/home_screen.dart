import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/activity.dart';
import '../services/activity_database.dart';
import '../services/settings_service.dart';
import '../widgets/activity_card.dart';
import '../widgets/metric_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onStart});
  final VoidCallback onStart;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = ActivityDatabase.instance;
  List<Activity> _activities = [];
  String _name = 'Athlete';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final activities = await _db.getActivities(limit: 50);
    final name = await SettingsService.instance.getName();
    if (!mounted) return;
    setState(() {
      _activities = activities;
      _name = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final week = _activities.where((a) => a.startedAt.isAfter(weekAgo));
    final weekDistance = week.fold<double>(0, (sum, a) => sum + a.distanceMeters);
    final weekTime = week.fold<int>(0, (sum, a) => sum + a.durationSeconds);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back,', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    Text(_name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(Icons.person_rounded, color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withBlue(220)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.route_rounded, color: Colors.white, size: 28),
                const SizedBox(height: 18),
                Text('Ready to move?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Start a GPS activity and keep the complete route on this device.', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Theme.of(context).colorScheme.primary),
                  onPressed: widget.onStart,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start activity'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Last 7 days', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: MetricCard(label: 'Distance', value: weekDistance.toStringAsFixed(1), unit: 'km', icon: Icons.straighten_rounded)),
              const SizedBox(width: 12),
              Expanded(child: MetricCard(label: 'Time', value: _formatHours(weekTime), unit: 'h', icon: Icons.timer_outlined)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent activities', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              Text(DateFormat('MMM yyyy').format(DateTime.now()), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          if (_activities.isEmpty)
            _EmptyState(onStart: widget.onStart)
          else
            ..._activities.take(5).map((activity) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ActivityCard(activity: activity),
            )),
        ],
      ),
    );
  }

  String _formatHours(int seconds) => (seconds / 3600).toStringAsFixed(1);
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Column(
        children: [
          const Icon(Icons.directions_run_rounded, size: 48),
          const SizedBox(height: 12),
          const Text('No activities yet.'),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onStart, child: const Text('Record your first one')),
        ],
      ),
    );
  }
}
