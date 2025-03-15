# flutter_yt_dlp

A Flutter plugin for downloading media using `yt-dlp` and FFmpeg, allowing users to download video and audio in their raw formats or converted to mp4 for video formats and mp3 for audio-only formats. It also provides the option to merge video-only formats with audio-only formats for greater flexibility, especially when raw video with sound formats are unavailable. Primarily developed with assistance from Grok, an AI by xAI.

## Features

- **Fetch Media Formats**: Retrieve video and audio formats from URLs in a unified way.
- **Download Media**: Download raw video+sound, merged video+audio, or audio-only formats, with the option to keep raw formats or convert to mp4 (video) or mp3 (audio-only).
- **Merging Option**: Combine video-only and audio-only formats into a single mp4 file for diverse format support.
- **Progress Monitoring**: Real-time updates on download progress and state via event streams.
- **Cancel Downloads**: Cancel ongoing downloads using task IDs.
- **Modular Design**: Code organized into `models.dart`, `utils.dart`, `format_categorizer.dart`, and `flutter_yt_dlp.dart` for maintainability.

## Platform Support

- **Android Only**: Utilizes Chaquopy for Python integration, limiting support to Android (minimum SDK 24, Android 7.0+).
- iOS support is not currently implemented.

## Installation

Add the plugin to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_yt_dlp: ^0.2.0
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

**NDK ABI Filters**: Supports `armeabi-v7a`, `arm64-v8a`, `x86`, and `x86_64` for broader device compatibility.

## Usage

### Initialize the Plugin

```dart
import 'package:flutter_yt_dlp/flutter_yt_dlp.dart';

void main() {
  final client = FlutterYtDlpClient();
  runApp(MyApp(client: client));
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
final client = FlutterYtDlpClient();
final url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ";
final videoInfo = await client.getVideoInfo(url);
final rawVideoFormats = videoInfo['rawVideoWithSoundFormats'] as List<Map<String, dynamic>>;
final mergeFormats = videoInfo['mergeFormats'] as List<Map<String, dynamic>>;
final rawAudioFormats = videoInfo['rawAudioOnlyFormats'] as List<Map<String, dynamic>>;
```

### Start a Download

```dart
import 'package:path_provider/path_provider.dart';

final outputDir = (await getExternalStorageDirectory())!.path;
final format = rawVideoFormats.first;
final taskId = await client.startDownload(
  format: {...format, 'downloadAsRaw': true}, // Set to false to convert to mp4/mp3
  outputDir: outputDir,
  url: url,
  overwrite: true,
  overrideName: "MyVideo",
);

client.getDownloadEvents().listen((event) {
  if (event['taskId'] != taskId) return;
  if (event['type'] == 'progress') {
    final progress = DownloadProgress.fromMap(event);
    print("Progress: ${(progress.percentage * 100).toStringAsFixed(1)}%");
  } else if (event['type'] == 'state') {
    final state = DownloadState.values[event['state'] as int];
    print("State: $state");
  }
});
```

### Cancel a Download

```dart
await client.cancelDownload(taskId);
```

## Format Types

- **Format**: Base class for audio-only formats, containing `formatId`, `ext`, `resolution`, `bitrate`, and `size`.
- **CombinedFormat**: Extends `Format` for video+sound formats, with a `needsConversion` flag indicating if it’s not mp4.
- **MergeFormat**: Represents separate video-only and audio-only formats to be merged into mp4.

## Example

See the `example/` directory for a sample app with a UI demonstrating format selection (raw or converted), merging options, downloads, and cancellation.

## Limitations

- **Android Only**: No iOS support due to Chaquopy.
- **App Size**: Chaquopy and FFmpeg increase APK size. Use `flutter build apk --split-per-abi` to reduce it.
- **Storage Access**: Android 10+ scoped storage limits direct path access; use `path_provider`.

## Troubleshooting

- **Permission Denied**: Ensure permissions (e.g., storage or internet) are granted in the app’s manifest and requested at runtime if needed.
- **No Formats Found**: Verify the URL is valid and supported by `yt-dlp`. Test with a known working URL.
- **Download Fails**: Enable logging in `FlutterYtDlpClient` instantiation (e.g., `FlutterYtDlpClient()`) and check logs for errors.
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

  Test with the default `FlutterSurfaceView` first, and apply this fix only if needed.

## Credits

Developed with assistance from Grok by xAI.

## License

MIT License. Respect yt-dlp (Unlicense) and FFmpeg (LGPL) licenses in your app.
