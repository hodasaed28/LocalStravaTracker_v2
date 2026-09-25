import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/activity.dart';
import '../models/track_point.dart';

class ActivityDatabase {
  ActivityDatabase._();
  static final ActivityDatabase instance = ActivityDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, 'stride_local.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE activities (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            title TEXT NOT NULL,
            started_at INTEGER NOT NULL,
            ended_at INTEGER,
            duration_seconds INTEGER NOT NULL,
            distance_m REAL NOT NULL,
            avg_speed_mps REAL NOT NULL,
            max_speed_mps REAL NOT NULL,
            elevation_gain_m REAL NOT NULL,
            calories REAL NOT NULL,
            notes TEXT NOT NULL DEFAULT ''
          )
        ''');
        await db.execute('''
          CREATE TABLE track_points (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            activity_id INTEGER NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            altitude REAL NOT NULL,
            accuracy REAL NOT NULL,
            speed_mps REAL NOT NULL,
            bearing REAL NOT NULL,
            timestamp INTEGER NOT NULL,
            FOREIGN KEY(activity_id) REFERENCES activities(id) ON DELETE CASCADE
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_track_points_activity ON track_points(activity_id)',
        );
        await db.execute(
          'CREATE INDEX idx_activities_started ON activities(started_at DESC)',
        );
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
    return _db!;
  }

  Future<int> insertActivity(Activity activity) async {
    final db = await database;
    final map = activity.toMap()..remove('id');
    return db.insert('activities', map);
  }

  Future<void> updateActivity(Activity activity) async {
    final db = await database;
    if (activity.id == null) return;
    final map = activity.toMap()..remove('id');
    await db.update(
      'activities',
      map,
      where: 'id = ?',
      whereArgs: [activity.id],
    );
  }

  Future<void> insertPoint(TrackPoint point, int activityId) async {
    final db = await database;
    await db.insert('track_points', point.toMap(activityId));
  }

  Future<List<Activity>> getActivities({int limit = 100}) async {
    final db = await database;
    final rows = await db.query(
      'activities',
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return rows.map(Activity.fromMap).toList();
  }

  Future<Activity?> getActivity(int id) async {
    final db = await database;
    final rows = await db.query(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Activity.fromMap(rows.first);
  }

  Future<List<TrackPoint>> getPoints(int activityId) async {
    final db = await database;
    final rows = await db.query(
      'track_points',
      where: 'activity_id = ?',
      whereArgs: [activityId],
      orderBy: 'timestamp ASC',
    );
    return rows.map(TrackPoint.fromMap).toList();
  }

  Future<void> deleteActivity(int id) async {
    final db = await database;
    await db.delete('track_points', where: 'activity_id = ?', whereArgs: [id]);
    await db.delete('activities', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    final db = await database;
    await db.delete('track_points');
    await db.delete('activities');
  }
}
