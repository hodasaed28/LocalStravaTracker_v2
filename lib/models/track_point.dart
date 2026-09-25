class TrackPoint {
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final double speedMps;
  final double bearing;
  final DateTime timestamp;

  const TrackPoint({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.speedMps,
    required this.bearing,
    required this.timestamp,
  });

  Map<String, Object?> toMap(int activityId) {
    return {
      'activity_id': activityId,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'speed_mps': speedMps,
      'bearing': bearing,
      'timestamp': timestamp.toUtc().millisecondsSinceEpoch,
    };
  }

  factory TrackPoint.fromMap(Map<String, Object?> map) {
    return TrackPoint(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      altitude: (map['altitude'] as num?)?.toDouble() ?? 0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0,
      speedMps: (map['speed_mps'] as num?)?.toDouble() ?? 0,
      bearing: (map['bearing'] as num?)?.toDouble() ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as num).toInt(),
        isUtc: true,
      ).toLocal(),
    );
  }
}
