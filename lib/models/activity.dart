import 'track_point.dart';

enum ActivityType {
  run,
  walk,
  cycle,
  hike;

  String get label {
    switch (this) {
      case ActivityType.run:
        return 'Run';
      case ActivityType.walk:
        return 'Walk';
      case ActivityType.cycle:
        return 'Cycling';
      case ActivityType.hike:
        return 'Hike';
    }
  }

  String get dbValue => name;

  static ActivityType fromDb(String value) {
    return ActivityType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ActivityType.run,
    );
  }
}


class Activity {
  final int? id;
  final ActivityType type;
  final String title;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final double distanceMeters;
  final double avgSpeedMps;
  final double maxSpeedMps;
  final double elevationGainMeters;
  final double calories;
  final String notes;

  const Activity({
    this.id,
    required this.type,
    required this.title,
    required this.startedAt,
    this.endedAt,
    required this.durationSeconds,
    required this.distanceMeters,
    required this.avgSpeedMps,
    required this.maxSpeedMps,
    required this.elevationGainMeters,
    required this.calories,
    this.notes = '',
  });

  Activity copyWith({
    int? id,
    ActivityType? type,
    String? title,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
    double? distanceMeters,
    double? avgSpeedMps,
    double? maxSpeedMps,
    double? elevationGainMeters,
    double? calories,
    String? notes,
  }) {
    return Activity(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      avgSpeedMps: avgSpeedMps ?? this.avgSpeedMps,
      maxSpeedMps: maxSpeedMps ?? this.maxSpeedMps,
      elevationGainMeters:
          elevationGainMeters ?? this.elevationGainMeters,
      calories: calories ?? this.calories,
      notes: notes ?? this.notes,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'type': type.dbValue,
      'title': title,
      'started_at': startedAt.toUtc().millisecondsSinceEpoch,
      'ended_at': endedAt?.toUtc().millisecondsSinceEpoch,
      'duration_seconds': durationSeconds,
      'distance_m': distanceMeters,
      'avg_speed_mps': avgSpeedMps,
      'max_speed_mps': maxSpeedMps,
      'elevation_gain_m': elevationGainMeters,
      'calories': calories,
      'notes': notes,
    };
  }

  factory Activity.fromMap(Map<String, Object?> map) {
    return Activity(
      id: (map['id'] as num?)?.toInt(),
      type: ActivityType.fromDb(map['type'] as String? ?? 'run'),
      title: map['title'] as String? ?? 'Activity',
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['started_at'] as num).toInt(),
        isUtc: true,
      ).toLocal(),
      endedAt: map['ended_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              (map['ended_at'] as num).toInt(),
              isUtc: true,
            ).toLocal(),
      durationSeconds: (map['duration_seconds'] as num?)?.toInt() ?? 0,
      distanceMeters: (map['distance_m'] as num?)?.toDouble() ?? 0,
      avgSpeedMps: (map['avg_speed_mps'] as num?)?.toDouble() ?? 0,
      maxSpeedMps: (map['max_speed_mps'] as num?)?.toDouble() ?? 0,
      elevationGainMeters:
          (map['elevation_gain_m'] as num?)?.toDouble() ?? 0,
      calories: (map['calories'] as num?)?.toDouble() ?? 0,
      notes: map['notes'] as String? ?? '',
    );
  }

  double get paceSecondsPerKm => avgSpeedMps <= 0 ? 0 : 1000 / avgSpeedMps;

  List<TrackPoint> route = const [];
}
