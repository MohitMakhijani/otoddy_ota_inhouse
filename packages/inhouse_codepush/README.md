# In-House Code Push (Flutter Package)

A drop-in over-the-air (OTA) code push client for Flutter applications. Allows you to deliver instant Dart bug fixes and UI updates to your users without going through app store review or re-installing APKs.

---

## 1. Installation

Add `inhouse_codepush` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  inhouse_codepush:
    path: path/to/inhouse-codepush/packages/inhouse_codepush
    # Or from git:
    # git:
    #   url: https://github.com/your-org/inhouse-codepush.git
    #   path: packages/inhouse_codepush
```

---

## 2. Usage in Dart

Initialize `InhouseCodePush` early in your `main()`:

```dart
import 'package:flutter/material.dart';
import 'package:inhouse_codepush/inhouse_codepush.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  InhouseCodePush.init(
    serverUrls: [
      'https://codepush.yourdomain.com', // Production server / tunnel
      'http://10.0.2.2:8080',            // Android emulator local testing
      'http://localhost:8080',           // USB device (adb reverse tcp:8080 tcp:8080)
    ],
    appId: 'com.example.myapp',
    releaseVersion: '1.0.0', // Must match installed app release
    onPatchReady: (patchNumber) {
      debugPrint('Patch #$patchNumber is downloaded and ready for next launch!');
    },
  );

  runApp(const MyApp());
}
```

---

## 3. Android Setup (One-Time)

### A. Add Internet Permission
In `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <application
        android:usesCleartextTraffic="true" ...> <!-- Only needed if using plain HTTP in dev -->
```

### B. Enable Hooked Engine in Gradle
In your root `android/build.gradle.kts` (or `build.gradle`):

```kotlin
// In build.gradle.kts
val localEngineMaven: String? = System.getenv("LOCAL_ENGINE_MAVEN")
allprojects {
    repositories {
        if (!localEngineMaven.isNullOrBlank()) {
            maven { url = java.io.File(localEngineMaven).toURI() }
        }
        google()
        mavenCentral()
    }
}
```

---

## 4. Shipping Your Baseline Build

Build your initial release APK or Play Store App Bundle with `LOCAL_ENGINE_MAVEN` active:

```powershell
$env:LOCAL_ENGINE_MAVEN = "C:\path\to\inhouse-codepush\local-engine-maven"
flutter build apk --release
# or: flutter build appbundle --release
```

---

## 5. Pushing OTA Patches

When you make Dart changes (bug fixes, UI updates):
```powershell
powershell -ExecutionPolicy Bypass -File path\to\tooling\push-patch.ps1 -TargetRelease 1.0.0 -Arch arm64
```

On next launch, your users will download and run the new patch automatically!
