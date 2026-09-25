# Stride Local

A privacy-first, local-only activity tracker inspired by the core experience of apps such as Strava.

## What it does

- Records running, walking, cycling and hiking activities.
- Uses GPS for route tracking, distance, speed, pace and elevation gain.
- Keeps activities and GPS points in a local SQLite database on the device.
- Continues Android tracking in the background with a visible foreground location notification.
- Shows route maps with OpenStreetMap tiles.
- Shows activity history, detail pages and monthly statistics.
- Exports any activity as GPX and shares it through the native share sheet.
- Provides local settings for profile weight, distance unit and map style.
- No user accounts, no remote database, no analytics SDK and no automatic upload.

## Important architecture choice

This project deliberately has **no backend**. Every installation has its own isolated data store. If a user deletes the app without a backup/export, the local activity history is lost.

## Map tiles

The default map uses OpenStreetMap's public raster tile endpoint. Keep the attribution visible. For a public/high-volume deployment, use a hosted tile provider or your own tile infrastructure and update `lib/services/map_service.dart`.

## Prerequisites

- Flutter stable 3.47.x or newer.
- Dart 3.12+ (bundled with the required Flutter release).
- Java 17 for Android builds.
- Android Studio with Android SDK installed.
- Xcode 16+ for iOS builds.

## Run

From a normal Flutter checkout, generate/update the platform scaffolding once with:

```bash
flutter create --platforms=android,ios --org com.mahmoud .
```

Then restore/verify the project files in this repository (`android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`, and the custom source tree), and run:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

> The source tree is complete, but Flutter/Gradle/Xcode generate a number of machine/version-specific platform files. Keeping those generated files out of the archive avoids pinning your machine to a particular SDK installation.

## Android background tracking

The app declares fine/coarse location, background location and Android foreground-service location permissions. Android may still restrict background execution depending on battery optimization and user settings.

When publishing to Google Play, review the current location-permission and background-location policy before release.

## iOS background tracking

The project declares location usage strings and the `location` background mode. Test background recording on a physical device.

## Project structure

```text
lib/
  app.dart
  main.dart
  models/
    activity.dart
    track_point.dart
  services/
    activity_database.dart
    gpx_service.dart
    map_service.dart
    settings_service.dart
    tracking_service.dart
  screens/
    activity_detail_screen.dart
    activities_screen.dart
    home_screen.dart
    record_screen.dart
    settings_screen.dart
    stats_screen.dart
  widgets/
    activity_card.dart
    metric_card.dart
    route_map.dart
```

## GitHub

```bash
git init
git add .
git commit -m "Initial Stride Local app"
git branch -M main
git remote add origin https://github.com/YOUR_USER/stride-local.git
git push -u origin main
```

## Roadmap ideas

- On-device route cleanup / GPS spike filtering.
- Personal goals and streaks.
- Automatic lap/split detection.
- Personal bests and route records.
- Heatmap-style local history.
- Offline map tile caching with a provider that permits caching.
- GPX import.
- FIT/TCX import/export.
- Wear OS companion.
- Optional encrypted local backup/restore.
- Optional self-hosted sync server (separate from the default architecture).
