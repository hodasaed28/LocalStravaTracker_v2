import 'package:flutter/material.dart';

import '../models/activity.dart';
import '../services/activity_database.dart';
import '../widgets/activity_card.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  List<Activity> _activities = [];
  ActivityType? _filter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final value = await ActivityDatabase.instance.getActivities();
    if (!mounted) return;
    setState(() => _activities = value);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == null ? _activities : _activities.where((a) => a.type == _filter).toList();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text('Activities', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(label: const Text('All'), selected: _filter == null, onSelected: (_) => setState(() => _filter = null)),
                const SizedBox(width: 8),
                ...ActivityType.values.map((type) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(label: Text(type.label), selected: _filter == type, onSelected: (_) => setState(() => _filter = type)),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text('No activities match this filter.')),
            )
          else
            ...filtered.map((activity) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ActivityCard(activity: activity),
            )),
        ],
      ),
    );
  }
}
