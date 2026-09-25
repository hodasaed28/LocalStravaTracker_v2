import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:latlong2/latlong.dart';

import '../models/activity.dart';
import '../models/track_point.dart';
import 'activity_database.dart';

class TrackingService extends ChangeNotifier {
  TrackingService({ActivityDatabase? database}) : _database = database ?? ActivityDatabase.instance;

  final ActivityDatabase _database;
  StreamSubscription<geo.Position>? _positionSubscription;
  Timer? _uiTimer;
  Stopwatch _stopwatch = Stopwatch();

  Activity? currentActivity;
  ActivityType? selectedType;
  bool isRecording = false;
  bool isPaused = false;
  bool isPreparing = false;
  String? errorMessage;
  double distanceMeters = 0;
  double maxSpeedMps = 0;
  double elevationGainMeters = 0;
  double calories = 0;
  geo.Position? currentPosition;
  final List<TrackPoint> points = [];

  int get elapsedSeconds => _stopwatch.elapsed.inSeconds;
  double get averageSpeedMps => elapsedSeconds <= 0 ? 0 : distanceMeters / elapsedSeconds;

  Future<void> start(ActivityType type, {double weightKg = 70}) async {
    if (isRecording) return;
    isPreparing = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _ensureLocationReady();
      final now = DateTime.now();
      final title = '${type.label} • ${_formatDate(now)}';
      final activity = Activity(
        type: type,
        title: title,
        startedAt: now,
        durationSeconds: 0,
        distanceMeters: 0,
        avgSpeedMps: 0,
        maxSpeedMps: 0,
        elevationGainMeters: 0,
        calories: 0,
      );
      final id = await _database.insertActivity(activity);
      currentActivity = activity.copyWith(id: id);
      selectedType = type;
      isRecording = true;
      isPaused = false;
      distanceMeters = 0;
      maxSpeedMps = 0;
      elevationGainMeters = 0;
      calories = 0;
      points.clear();
      currentPosition = null;
      _stopwatch = Stopwatch()..start();
      _uiTimer?.cancel();
      _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _recalculateCalories(weightKg);
        notifyListeners();
      });

      final settings = switch (defaultTargetPlatform) {
        TargetPlatform.android => geo.AndroidSettings(
            accuracy: geo.LocationAccuracy.high,
            distanceFilter: 5,
            intervalDuration: const Duration(seconds: 2),
            foregroundNotificationConfig: const geo.ForegroundNotificationConfig(
              notificationTitle: 'Stride Local is tracking',
              notificationText: 'Your activity route is being recorded.',
              enableWakeLock: true,
              setOngoing: true,
              notificationIcon: geo.AndroidResource(
                name: 'ic_stat_run',
                defType: 'drawable',
              ),
            ),
          ),
        TargetPlatform.iOS => geo.AppleSettings(
            accuracy: geo.LocationAccuracy.best,
            activityType: geo.ActivityType.fitness,
            distanceFilter: 5,
            pauseLocationUpdatesAutomatically: false,
            showBackgroundLocationIndicator: true,
          ),
        _ => geo.LocationSettings(
            accuracy: geo.LocationAccuracy.high,
            distanceFilter: 5,
          ),
      };

      _positionSubscription = geo.Geolocator.getPositionStream(locationSettings: settings).listen(
        (position) => _handlePosition(position, weightKg),
        onError: (Object error) {
          errorMessage = 'Location stream error: $error';
          notifyListeners();
        },
      );
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isPreparing = false;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    if (!isRecording || isPaused) return;
    _stopwatch.stop();
    isPaused = true;
    await _persistSnapshot();
    notifyListeners();
  }

  Future<void> resume() async {
    if (!isRecording || !isPaused) return;
    isPaused = false;
    _stopwatch.start();
    notifyListeners();
  }

  Future<Activity?> stop() async {
    if (!isRecording || currentActivity == null) return null;
    _stopwatch.stop();
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _uiTimer?.cancel();
    _uiTimer = null;

    final finished = currentActivity!.copyWith(
      endedAt: DateTime.now(),
      durationSeconds: elapsedSeconds,
      distanceMeters: distanceMeters,
      avgSpeedMps: averageSpeedMps,
      maxSpeedMps: maxSpeedMps,
      elevationGainMeters: elevationGainMeters,
      calories: calories,
    );
    await _database.updateActivity(finished);

    isRecording = false;
    isPaused = false;
    currentActivity = null;
    selectedType = null;
    notifyListeners();
    return finished;
  }

  Future<void> disposeTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _uiTimer?.cancel();
    _uiTimer = null;
  }

  Future<void> _ensureLocationReady() async {
    final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Turn on GPS and try again.');
    }
    var permission = await geo.Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Location permission was denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is permanently denied. Enable it from system settings.');
    }
  }

  void _handlePosition(geo.Position position, double weightKg) {
    currentPosition = position;
    if (!isRecording || isPaused) {
      notifyListeners();
      return;
    }
    if (position.accuracy.isFinite && position.accuracy > 60) {
      notifyListeners();
      return;
    }

    final point = TrackPoint(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude.isFinite ? position.altitude : 0,
      accuracy: position.accuracy,
      speedMps: position.speed.isFinite && position.speed >= 0 ? position.speed : 0,
      bearing: position.heading.isFinite ? position.heading : 0,
      timestamp: position.timestamp,
    );

    final previous = points.isEmpty ? null : points.last;
    if (previous != null) {
      final segment = const Distance()(LatLng(previous.latitude, previous.longitude), LatLng(point.latitude, point.longitude));
      final seconds = point.timestamp.difference(previous.timestamp).inMilliseconds / 1000.0;
      if (seconds > 0 && segment < 250) {
        distanceMeters += segment;
      } else if (segment >= 250) {
        return; // likely GPS jump
      }
      final altitudeDelta = point.altitude - previous.altitude;
      if (altitudeDelta > 1 && altitudeDelta < 25) {
        elevationGainMeters += altitudeDelta;
      }
    }

    maxSpeedMps = point.speedMps > maxSpeedMps ? point.speedMps : maxSpeedMps;
    points.add(point);
    if (currentActivity?.id != null) {
      _database.insertPoint(point, currentActivity!.id!);
    }
    _recalculateCalories(weightKg);
    notifyListeners();
  }

  void _recalculateCalories(double weightKg) {
    final type = selectedType ?? ActivityType.run;
    final met = switch (type) {
      ActivityType.run => averageSpeedMps >= 3.0 ? 9.8 : 8.0,
      ActivityType.walk => 3.5,
      ActivityType.cycle => 7.5,
      ActivityType.hike => 6.0,
    };
    calories = met * 3.5 * weightKg / 200 * (elapsedSeconds / 60.0);
  }

  Future<void> _persistSnapshot() async {
    final activity = currentActivity;
    if (activity?.id == null) return;
    await _database.updateActivity(
      activity!.copyWith(
        durationSeconds: elapsedSeconds,
        distanceMeters: distanceMeters,
        avgSpeedMps: averageSpeedMps,
        maxSpeedMps: maxSpeedMps,
        elevationGainMeters: elevationGainMeters,
        calories: calories,
      ),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  @override
  void dispose() {
    disposeTracking();
    super.dispose();
  }
}
