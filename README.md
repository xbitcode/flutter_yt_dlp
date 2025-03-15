# flutter_yt_dlp

A Flutter plugin for downloading media using `yt-dlp` and FFmpeg, allowing users to download video and audio with options to keep raw formats or convert to mp4 (video) or mp3 (audio). It supports merging video-only and audio-only formats for flexibility when raw video with sound is unavailable. Primarily developed with assistance from Grok, an AI by xAI.

## Features

- **Fetch Media Formats**: Retrieve video and audio formats by type using a single method with constants (`FormatTypes`).
- **Download Media**: Download video with sound (`convertToMp4`), audio-only (`convertToMp3`), or merged formats, with explicit conversion flags.
- **Merging Option**: Combine video-only and audio-only formats into a single mp4 file.
- **Progress Monitoring**: Real-time updates via event streams.
- **Cancel Downloads**: Cancel ongoing downloads using task IDs.
- **Modular Design**: Organized into `models.dart`, `utils.dart`, `format_categorizer.dart`, and `flutter_yt_dlp.dart`.

## Platform Support

- **Android Only**: Uses Chaquopy, limiting support to Android (minimum SDK 24, Android 7.0+).

## Installation

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter_yt_dlp: ^0.2.0
```

Run `flutter pub get`.

Or from GitHub:

```yaml
dependencies:
  flutter_yt_dlp:
    git:
      url: <https://github.com/utoxas/flutter_yt_dlp.git>
      ref: master
```

### Android Configuration

**Permissions**: Add to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

**Minimum SDK**: Set `minSdk` to 24+ in `android/app/build.gradle`.

**NDK ABI Filters**: Supports `armeabi-v7a`, `arm64-v8a`, `x86`, `x86_64`.

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
final url = "<https://www.youtube.com/watch?v=dQw4w9WgXcQ>";
final videoInfo = await client.getVideoInfo(url);
final videoFormats = await client.getFormats(url, FormatTypes.videoWithSound);
final mergeFormats = await client.getFormats(url, FormatTypes.merge);
final audioFormats = await client.getFormats(url, FormatTypes.audioOnly);
```

### Start a Download

```dart
import 'package:path_provider/path_provider.dart';

final outputDir = (await getExternalStorageDirectory())!.path;
final format = videoFormats.first;
final taskId = await client.startDownload(
  format: format,
  outputDir: outputDir,
  url: url,
  overwrite: true,
  overrideName: "MyVideo",
  convertToMp4: true, // Convert video to mp4
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

- **FormatTypes.videoWithSound**: Video with sound, convertible to mp4.
- **FormatTypes.merge**: Video-only and audio-only formats to merge into mp4.
- **FormatTypes.audioOnly**: Audio-only formats, convertible to mp3.

## Example

See `example/` for a sample app demonstrating the updated API.

## Limitations

- **Android Only**: No iOS support due to Chaquopy.
- **App Size**: Chaquopy and FFmpeg increase APK size. Use `flutter build apk --split-per-abi`.
- **Storage Access**: Android 10+ scoped storage limits direct path access; use `path_provider`.

## Troubleshooting

- **Permission Denied**: Ensure permissions are granted.
- **No Formats Found**: Verify URL validity with `yt-dlp`.
- **Download Fails**: Enable logging in `FlutterYtDlpClient` and check logs.
- **Initialization Errors**: Review console for Python runtime issues.

## Credits

Developed with assistance from Grok by xAI.

## License

MIT License. Respect yt-dlp (Unlicense) and FFmpeg (LGPL) licenses.
