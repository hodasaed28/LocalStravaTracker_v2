# Stride Local — Project Specification

## 1. Product idea

Stride Local is a Strava-style activity tracker designed around a different product rule: **the device is the account**.

There is no mandatory account, no backend, no central database and no social graph. Every installation maintains its own history locally. A user can export GPX files when they choose to move a route to another service.

## 2. Core feature set

### Activity recording

Supported activity types:

- Run
- Walk
- Cycling
- Hike

During recording the app collects GPS positions and calculates:

- Distance
- Elapsed moving time
- Average speed
- Average running pace
- Maximum speed
- Elevation gain estimate
- Calorie estimate
- Route polyline
- GPS accuracy per point
- Timestamp per point
- Heading/bearing when supplied by the OS

The tracker filters obvious GPS spikes and ignores locations with very poor reported accuracy.

### Recording controls

- Start
- Pause
- Resume
- Finish
- Live distance
- Live time
- Live pace
- Live calories
- Current location marker
- Live route polyline

### Background tracking

Android uses Geolocator's foreground-notification location configuration. The app declares the Android permissions required for a foreground location service, including `FOREGROUND_SERVICE_LOCATION`. The user sees a persistent system notification while a recording is active.

iOS declares location usage strings and the `location` background mode. Always test background tracking on physical devices.

### Activity history

- All activities
- Filter by type
- Date and time
- Distance
- Duration
- Activity type
- Open detail page
- Delete an activity

### Activity detail

- Full route map
- Distance
- Duration
- Pace
- Elevation gain
- Calories
- Number of GPS points
- GPX export/share
- Delete

### Local statistics

- Total activities
- Total distance
- Total time
- Total elevation
- Total calories
- Six-month distance bar chart

### Local preferences

- Athlete name
- Weight
- Kilometer/mile preference stored for future UI expansion
- Light/dark/system theme preference stored locally
- Delete all local activity data

## 3. Storage model

SQLite contains two tables.

### activities

Stores the summary record for each session.

### track_points

Stores the raw-ish GPS route samples linked to an activity ID.

This separation is intentional: the activity table stays small and fast for history/statistics, while route data remains granular and can be loaded only on demand.

## 4. Why local-first

The local architecture gives the project:

- Privacy by default
- No hosting bill
- No database maintenance
- Offline-safe history storage
- Very simple deployment
- A natural path to optional GPX/FIT/TCX export
- A natural path to an optional self-hosted synchronization service later

## 5. Recommended next releases

### v1.1 — Better recording quality

- Satellite/GPS status indicator
- Better speed smoothing
- Better altitude smoothing
- Auto-pause while stationary
- Manual lap button
- Kilometer/mile split alerts
- Lock-screen activity controls

### v1.2 — Personal performance

- Personal bests
- Best 1 km / 5 km / 10 km / half-marathon segments
- Weekly/monthly/yearly goals
- Streaks
- Training load estimates
- Heart-rate support through a connected source

### v1.3 — Maps & routes

- Saved favorite routes
- GPX import
- Route naming
- Route preview
- Offline map regions using a tile/data provider whose license permits caching
- Breadcrumb navigation

### v1.4 — Wearables

- Wear OS companion
- Apple Watch companion
- Heart rate
- Cadence
- Step count
- Wrist GPS integration

### v1.5 — Backup without a central service

- Encrypted local backup
- Restore backup
- Export all activities as a ZIP of GPX files
- Optional encrypted file sync using a user's own cloud storage

### v2 — Optional self-hosted sync

Keep this outside the default app. A future server can provide:

- Device registration
- End-to-end encrypted activity synchronization
- Conflict handling
- Multi-device restore

The app should still work when the server is unavailable.

## 6. Engineering rules

- Keep calculation logic separate from UI.
- Store UTC timestamps; display local time.
- Never require a network request to open activity history.
- Never put private activity data into logs by default.
- Keep export formats deterministic and testable.
- Add automated tests around distance calculation, pace, calorie calculation and GPX generation.
- Treat location permission and battery behavior as platform-specific concerns.

## 7. GitHub issue backlog

Suggested first issues:

1. Add real unit conversion for km/mi.
2. Add auto-pause/auto-resume.
3. Add GPS signal quality widget.
4. Add route simplification to reduce polyline memory.
5. Add GPX import.
6. Add FIT export.
7. Add personal best detection.
8. Add encrypted local backup.
9. Add route heatmap.
10. Add widget/home-screen shortcut for quick recording.
11. Add notification actions for Pause/Resume/Finish.
12. Add integration tests on Android physical device.
13. Add iOS background recording test plan.
14. Add database migration framework before schema version 2.

## 8. Important deployment notes

Map tiles are not the same thing as GPS tracking. GPS positioning can continue without internet, but a normal online raster map cannot display new areas without connectivity unless the app has cached/offline map data from a provider that permits that use.

For a public launch, replace the public OpenStreetMap tile endpoint with a provider or infrastructure intended for application traffic, and keep the required attribution.
