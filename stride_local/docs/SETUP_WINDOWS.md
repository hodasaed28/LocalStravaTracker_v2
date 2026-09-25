# Windows setup

## 1. Install the toolchain

Install Flutter stable 3.47.x or newer, Android Studio, Android SDK 35+, and Java 17.

Then open PowerShell:

```powershell
flutter doctor
```

Fix every Android/Xcode item relevant to your target platform before building.

## 2. Get dependencies

```powershell
cd path\to\stride_local
flutter pub get
```

## 3. Generate Flutter platform boilerplate when needed

This repository keeps the application source and the important native configuration in Git. Some Flutter/Xcode/Gradle generated files depend on your local SDK version.

When the platform wrapper is incomplete on your machine, back up the repository first and run:

```powershell
flutter create --platforms=android,ios --org com.mahmoud .
```

Then make sure the repository's custom files are still present:

- `android/app/src/main/AndroidManifest.xml`
- `android/app/build.gradle`
- `android/gradle.properties`
- `android/settings.gradle`
- `android/app/src/main/kotlin/com/mahmoud/stridelocal/MainActivity.kt`
- `ios/Runner/Info.plist`
- `ios/Runner/AppDelegate.swift`
- `ios/Podfile`

## 4. Analyze/test

```powershell
flutter analyze
flutter test
```

## 5. Run on an Android phone

Enable Developer Options + USB debugging, connect the phone, then:

```powershell
flutter devices
flutter run
```

For GPS testing, use a physical phone rather than an emulator. Test:

1. Start a run.
2. Turn the screen off.
3. Move for several minutes.
4. Confirm the route keeps growing.
5. Stop the activity.
6. Reopen the activity from History.
7. Export GPX.

## 6. GitHub

```powershell
git init
git add .
git commit -m "Initial Stride Local app"
git branch -M main
git remote add origin https://github.com/YOUR_USER/stride-local.git
git push -u origin main
```
