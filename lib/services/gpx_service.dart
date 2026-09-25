import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/activity.dart';
import '../models/track_point.dart';

class GpxService {
  static Future<File> createGpxFile(Activity activity, List<TrackPoint> points) async {
    final directory = await getTemporaryDirectory();
    final safeTitle = activity.title.replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_');
    final file = File(p.join(directory.path, '${safeTitle}_${activity.id ?? 'activity'}.gpx'));
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<gpx version="1.1" creator="Stride Local" xmlns="http://www.topografix.com/GPX/1/1">');
    buffer.writeln('<metadata><name>${_escape(activity.title)}</name></metadata>');
    buffer.writeln('<trk><name>${_escape(activity.title)}</name><trkseg>');
    for (final point in points) {
      buffer.write('<trkpt lat="${point.latitude.toStringAsFixed(7)}" lon="${point.longitude.toStringAsFixed(7)}">');
      buffer.write('<ele>${point.altitude.toStringAsFixed(2)}</ele>');
      buffer.write('<time>${point.timestamp.toUtc().toIso8601String()}</time>');
      buffer.writeln('</trkpt>');
    }
    buffer.writeln('</trkseg></trk>');
    buffer.writeln('</gpx>');
    await file.writeAsString(buffer.toString(), flush: true);
    return file;
  }

  static Future<void> shareGpx(Activity activity, List<TrackPoint> points) async {
    final file = await createGpxFile(activity, points);
    await SharePlus.instance.share(
      ShareParams(
        title: '${activity.title} GPX',
        text: 'GPX route exported from Stride Local.',
        files: [XFile(file.path)],
      ),
    );
  }

  static String _escape(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
