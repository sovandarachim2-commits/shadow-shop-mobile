# Shadow Shop Mobile – APK Build & Server Deployment Guide

This guide explains how to connect the Flutter mobile app to your deployed live backend server, compile the release APK, and install it on physical Android phones.

---

## 1. Configure Deployed Server URL

By default, the app uses `http://10.0.2.2:8001/api`, which is only accessible within the Android PC emulator. A real physical phone cannot access `10.0.2.2`.

### Option A: Edit `lib/config/app_config.dart` (Recommended)

Open [lib/config/app_config.dart](file:///c:/xampp/htdocs/Shadow%20Shop-mobile/lib/config/app_config.dart) and update `defaultValue`:

```dart
class AppConfig {
  AppConfig._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    // Replace with your deployed server domain or public IP (must end with /api):
    defaultValue: 'https://your-domain.com/api',
  );
}
```

### Option B: Pass dynamically at build time

You can pass the URL without modifying code by using `--dart-define`:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://your-domain.com/api
```

---

## 2. Network & Android Permissions (Already Configured)

In `android/app/src/main/AndroidManifest.xml`:
* `android.permission.INTERNET` is enabled.
* `android:usesCleartextTraffic="true"` is enabled (allows both `https://` and plain `http://` server IP addresses during testing).

---

## 3. Build the Release APK

Open PowerShell or Terminal in the project root (`c:\xampp\htdocs\Shadow Shop-mobile`) and run:

```bash
flutter build apk --release
```

### Build output location:
When the build finishes, your production-ready APK is generated at:
```
c:\xampp\htdocs\Shadow Shop-mobile\build\app\outputs\flutter-apk\app-release.apk
```

---

## 4. Install on Physical Android Devices

### Method 1: Send via Telegram / WhatsApp / Drive (Easiest)
1. Drag and drop `app-release.apk` into your Telegram "Saved Messages", Google Drive, or email.
2. Open the message on your phone and tap the file to download.
3. Tap the file to install (if prompted, enable **"Allow from this source"** in Android Settings).

### Method 2: Direct USB Installation via ADB
1. Connect your Android phone to your PC with a USB cable.
2. Enable **Developer Options** and turn on **USB Debugging** on your phone.
3. In your PC terminal, run:
   ```bash
   flutter install
   ```
   Or using ADB directly:
   ```bash
   adb install build\app\outputs\flutter-apk\app-release.apk
   ```

---

## 5. Backend Server Requirements Checklist

Ensure your deployed Django backend is configured to accept requests from the mobile app:

1. **ALLOWED_HOSTS**:
   In `backend/settings.py` (or environment variables), make sure your live domain or server IP is included:
   ```python
   ALLOWED_HOSTS = ['your-domain.com', 'api.your-domain.com', 'your.server.ip']
   ```

2. **CORS Headers**:
   If you have CORS enabled:
   ```python
   CORS_ALLOW_ALL_ORIGINS = True  # or include mobile user-agents
   ```

3. **Media & Static Files**:
   Ensure `/media/` (product photos, icons, banners) is properly served by Nginx / Caddy or Django so images load on the mobile app.

---

## 6. Quick Troubleshooting

| Issue | Solution |
| :--- | :--- |
| **Connection refused / Cannot reach server** | Check that `defaultValue` in `app_config.dart` does not say `localhost` or `10.0.2.2`. Use your public server IP or domain. |
| **Images not loading** | Verify your server's media URL (`https://your-domain.com/media/...`) is publicly accessible in a web browser. |
| **App blocked by Play Protect** | Tap **"More details"** -> **"Install anyway"** (normal for self-signed APKs not yet published to Google Play Store). |

