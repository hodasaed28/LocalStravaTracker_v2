import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/activity.dart';
import '../services/activity_database.dart';
import '../widgets/metric_card.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<Activity> _activities = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await ActivityDatabase.instance.getActivities(limit: 5000);
    if (!mounted) return;
    setState(() => _activities = value);
  }

  @override
  Widget build(BuildContext context) {
    final totalDistance = _activities.fold<double>(0, (s, a) => s + a.distanceMeters);
    final totalTime = _activities.fold<int>(0, (s, a) => s + a.durationSeconds);
    final totalCalories = _activities.fold<double>(0, (s, a) => s + a.calories);
    final totalElevation = _activities.fold<double>(0, (s, a) => s + a.elevationGainMeters);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text('Stats', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: MetricCard(label: 'Activities', value: '${_activities.length}', icon: Icons.fitness_center_rounded)),
              const SizedBox(width: 12),
              Expanded(child: MetricCard(label: 'Distance', value: (totalDistance / 1000).toStringAsFixed(1), unit: 'km', icon: Icons.route_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: MetricCard(label: 'Time', value: (totalTime / 3600).toStringAsFixed(1), unit: 'h', icon: Icons.timer_outlined)),
              const SizedBox(width: 12),
              Expanded(child: MetricCard(label: 'Elevation', value: totalElevation.toStringAsFixed(0), unit: 'm', icon: Icons.terrain_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          MetricCard(label: 'Calories', value: totalCalories.toStringAsFixed(0), unit: 'kcal', icon: Icons.local_fire_department_outlined),
          const SizedBox(height: 24),
          Text('Monthly distance', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Container(
            height: 280,
            padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.45)),
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(_monthShort(value.toInt())),
                      ),
                    ),
                  ),
                ),
                barGroups: _monthlyBars(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _monthlyBars() {
    final now = DateTime.now();
    return List.generate(6, (index) {
      final month = DateTime(now.year, now.month - (5 - index), 1);
      final distance = _activities.where((a) => a.startedAt.year == month.year && a.startedAt.month == month.month).fold<double>(0, (s, a) => s + a.distanceMeters) / 1000;
      return BarChartGroupData(
        x: index,
        barRods: [BarChartRodData(toY: distance, width: 18, borderRadius: BorderRadius.circular(5))],
      );
    });
  }

  String _monthShort(int index) {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month - (5 - index), 1);
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[d.month - 1];
  }
}
