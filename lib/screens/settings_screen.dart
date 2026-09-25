import 'package:flutter/material.dart';

import '../services/activity_database.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _name = TextEditingController();
  final _weight = TextEditingController();
  String _unit = 'km';
  String _theme = 'system';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = SettingsService.instance;
    _name.text = await prefs.getName();
    _weight.text = (await prefs.getWeight()).toStringAsFixed(0);
    _unit = await prefs.getUnit();
    _theme = await prefs.getTheme();
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    await SettingsService.instance.saveName(_name.text.trim().isEmpty ? 'Athlete' : _name.text.trim());
    await SettingsService.instance.saveWeight(double.tryParse(_weight.text) ?? 70);
    await SettingsService.instance.saveUnit(_unit);
    await SettingsService.instance.saveTheme(_theme);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
  }

  Future<void> _clearData() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all activities?'),
        content: const Text('This permanently deletes all routes and activity history stored on this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete everything')),
        ],
      ),
    );
    if (ok != true) return;
    await ActivityDatabase.instance.deleteAll();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local activity data deleted')));
  }

  @override
  void dispose() {
    _name.dispose();
    _weight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        _section(
          context,
          title: 'Profile',
          children: [
            TextField(controller: _name, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outline_rounded))),
            const SizedBox(height: 12),
            TextField(controller: _weight, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight (kg)', prefixIcon: Icon(Icons.monitor_weight_outlined))),
          ],
        ),
        const SizedBox(height: 16),
        _section(
          context,
          title: 'Preferences',
          children: [
            DropdownButtonFormField<String>(
              initialValue: _unit,
              decoration: const InputDecoration(labelText: 'Distance unit'),
              items: const [DropdownMenuItem(value: 'km', child: Text('Kilometers')), DropdownMenuItem(value: 'mi', child: Text('Miles'))],
              onChanged: (value) => setState(() => _unit = value ?? 'km'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _theme,
              decoration: const InputDecoration(labelText: 'Theme'),
              items: const [DropdownMenuItem(value: 'system', child: Text('System')), DropdownMenuItem(value: 'light', child: Text('Light')), DropdownMenuItem(value: 'dark', child: Text('Dark'))],
              onChanged: (value) => setState(() => _theme = value ?? 'system'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: _save, child: const Text('Save settings')),
        const SizedBox(height: 24),
        _section(
          context,
          title: 'Privacy & data',
          children: [
            const ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.phonelink_lock_rounded), title: Text('Local-first storage'), subtitle: Text('Activities stay in the app database on this device unless you export/share them.')),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: _clearData, icon: const Icon(Icons.delete_sweep_outlined), label: const Text('Delete all local activity data')),
          ],
        ),
        const SizedBox(height: 16),
        Text('Stride Local 1.0.0', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _section(BuildContext context, {required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}
