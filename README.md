# flutter_yt_dlp

A Flutter plugin for downloading and processing media using `yt-dlp` and FFmpeg, primarily developed with assistance from Grok, an AI by xAI.

## Features

- **Fetch Media Formats**: Retrieve various video and audio formats from URLs.
- **Download Media**: Support for raw video+sound, merged video+audio, and audio-only downloads.
- **Conversion**: Convert non-MP4 video formats to MP4 and non-MP3 audio formats to MP3.
- **Progress Monitoring**: Real-time updates on download progress and state.
- **Cancel Downloads**: Cancel ongoing downloads with `DownloadTask.cancel()`.
- **Byte Formatting**: Convert byte sizes to human-readable strings with `formatBytes`.
- **Modular Design**: Code organized into `models.dart`, `utils.dart`, and `flutter_yt_dlp.dart` for maintainability.

## Platform Support

- **Android Only**: Utilizes Chaquopy for Python integration, limiting support to Android (minimum SDK 24, Android 7.0+).
- iOS support is not currently implemented.

## Installation

Add the plugin to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_yt_dlp: ^0.1.4
```

Run `flutter pub get` to install it.

Alternatively, if using from GitHub:

```yaml
dependencies:
  flutter_yt_dlp:
    git:
      url: https://github.com/utoxas/flutter_yt_dlp.git
      ref: master
```

### Android Configuration

**Permissions**: Add the following to your app’s `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

**Minimum SDK**: Ensure `minSdk` is set to 24 or higher in `android/app/build.gradle`.

**NDK ABI Filters**: Updated to support `armeabi-v7a`, `arm64-v8a`, `x86`, and `x86_64` for broader device compatibility.

## Usage

### Initialize the Plugin

```dart
import 'package:flutter_yt_dlp/flutter_yt_dlp.dart';

void main() {
  FlutterYtDlpPlugin.initialize();
  runApp(MyApp());
}
```

### Request Permissions

```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestStoragePermission() async {
  return await Permission.storage.request().isGranted;
}
```

### Fetch Formats

```dart
final url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ";
final rawVideoFormats = await FlutterYtDlpPlugin.getAllRawVideoWithSoundFormats(url);
final mergeFormats = await FlutterYtDlpPlugin.getRawVideoAndAudioFormatsForMerge(url);
final convertVideoFormats = await FlutterYtDlpPlugin.getNonMp4VideoWithSoundFormatsForConversion(url);
final rawAudioFormats = await FlutterYtDlpPlugin.getAllRawAudioOnlyFormats(url);
final convertAudioFormats = await FlutterYtDlpPlugin.getNonMp3AudioOnlyFormatsForConversion(url);
```

### Start a Download

```dart
import 'package:path_provider/path_provider.dart';

final outputDir = (await getExternalStorageDirectory())!.path;
final format = rawVideoFormats.first;
final task = await FlutterYtDlpPlugin.download(
  format: format,
  outputDir: outputDir,
  url: url,
  originalName: "MyVideo",
  overwrite: true,
);

task.progressStream.listen((progress) {
  print("Progress: ${(progress.percentage * 100).toStringAsFixed(1)}%");
  print("Downloaded: ${FlutterYtDlpPlugin.formatBytes(progress.downloadedBytes)}");
});

task.stateStream.listen((state) {
  print("State: $state");
});
```

### Cancel a Download

```dart
await task.cancel();
```

### Format Bytes

```dart
final sizeInBytes = 1234567;
final readableSize = FlutterYtDlpPlugin.formatBytes(sizeInBytes); // e.g., "1.18 MB"
```

## Format Types

- **Format**: Base class for audio-only formats, containing `formatId`, `ext`, `resolution`, `bitrate`, and `size`.
- **CombinedFormat**: Extends `Format` for video+sound formats, with a `needsConversion` flag.
- **MergeFormat**: Represents separate video and audio formats to be merged into MP4.

## Example

See the `example/` directory for a sample app with a UI demonstrating downloads and cancellation.

## Limitations

- **Android Only**: No iOS support due to Chaquopy.
- **App Size**: Chaquopy and FFmpeg increase APK size. Use `flutter build apk --split-per-abi` to reduce it.
- **Storage Access**: Android 10+ scoped storage limits direct path access; use `path_provider`.

## Troubleshooting

- **Permission Denied**: Ensure permissions (e.g., storage or internet) are granted in the app’s manifest and requested at runtime if needed.
- **No Formats Found**: Verify the URL is valid and supported by `yt-dlp`. Test with a known working URL.
- **Download Fails**: Enable logging with `initialize()` (e.g., `FlutterYtDlp.initialize(enableLogging: true)`) and check the logs for detailed error messages.
- **Initialization Errors**: Review console output for exceptions during plugin initialization, such as Python runtime or dependency issues.
- **Excessive `cancelDraw` Logs on Android**: If logs show repeated `I/ViewRootImpl@...[MainActivity]: [DP] cancelDraw` messages (e.g., on some Samsung devices like Galaxy A20, Android 11), switch to `FlutterTextureView` by overriding `getRenderMode()` in your `MainActivity.kt`:

  ```kotlin
  package com.your.app

  import io.flutter.embedding.android.FlutterActivity
  import io.flutter.embedding.android.RenderMode

  class MainActivity : FlutterActivity() {
      override fun getRenderMode(): RenderMode {
          return RenderMode.texture
      }
  }
  ```

  This can resolve rendering instability but may not be necessary for all devices. Test with the default `FlutterSurfaceView` (no override) first, and apply this fix only if needed.

## Credits

Developed with assistance from Grok by xAI.

## License

MIT License. Respect yt-dlp (Unlicense) and FFmpeg (LGPL) licenses in your app.
