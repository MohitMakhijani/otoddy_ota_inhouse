# OtoddyOTA

[![pub package](https://img.shields.io/pub/v/otoddyota.svg)](https://pub.dev/packages/otoddyota)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A drop-in **Over-The-Air (OTA) Code Push client for Flutter applications**, engineered by **[OTODDY](https://otoddy.com)**.

Deliver instant Dart bug fixes, UI updates, and feature enhancements to your users over the air without waiting for App Store reviews or reinstalling APKs.

---

## 🏢 About OTODDY

**[OTODDY](https://otoddy.com)** is a product-focused technology company building software products, digital platforms, and developer technologies that solve real-world problems. We create scalable, reliable, and user-centric technology across mobility, healthcare, business software, and emerging digital domains.

* **Website**: [https://otoddy.com](https://otoddy.com)
* **GitHub**: [https://github.com/MohitMakhijani/otoddy_ota_inhouse](https://github.com/MohitMakhijani/otoddy_ota_inhouse)

---

## 🚀 Key Features

* **⚡ Zero-Friction Updates**: Push Dart code updates directly to running devices in seconds.
* **🛡️ Engine Snapshot Guard**: Verifies the Dart engine snapshot hash before loading, preventing crashes.
* **🔒 Atomic Downloads**: Safe, stream-piped downloads with atomic replacement.
* **🌐 Dynamic Architecture Detection**: Automatically resolves `arm64-v8a` vs. `x86_64` dynamically via Dart `Abi.current()`.
* **⛔ Remote Killswitch**: Instant emergency rollback if a patch contains critical issues.

---

## 📦 Installation

Add `otoddyota` to your Flutter app:

```bash
flutter pub add otoddyota
```

Or add it directly to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  otoddyota: ^1.0.1
```

---

## 💻 Usage

Initialize `OtoddyOTA` inside your `main()` before calling `runApp`:

```dart
import 'package:flutter/material.dart';
import 'package:otoddyota/otoddyota.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize OtoddyOTA early
  OtoddyOTA.init(
    serverUrls: [
      'https://codepush.yourdomain.com', // Your live production server
      'http://10.0.2.2:8080',            // Local Android emulator fallback
      'http://localhost:8080',           // USB device / localhost
    ],
    appId: 'com.yourcompany.yourapp',
    releaseVersion: '1.0.0', // Must match installed base release
    onPatchReady: (patchNumber) {
      debugPrint('==> New OtoddyOTA patch #$patchNumber ready for next restart!');
    },
  );

  runApp(const MyApp());
}
```

---

## ⚙️ Android Setup

### 1. Add Internet Permission
In `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
```

### 2. Configure Hooked Engine Repository
In your root `android/build.gradle.kts` (or `build.gradle`):
```kotlin
val localEngineMaven = System.getenv("LOCAL_ENGINE_MAVEN")
if (localEngineMaven != null) {
    allprojects {
        repositories {
            maven { url = java.io.File(localEngineMaven).toURI() }
        }
    }
}
```

---

## 📜 License

Distributed under the MIT License. See [LICENSE](LICENSE) for more information.

Built with ❤️ by **[OTODDY](https://otoddy.com)**.
