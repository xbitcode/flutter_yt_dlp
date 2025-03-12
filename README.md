# flutter_yt_dlp

A Flutter plugin for downloading and processing media using `yt-dlp` and FFmpeg, primarily developed with assistance from Grok, an AI by xAI.

## Features

- **Fetch Media Formats**: Retrieve various video and audio formats from URLs.
- **Download Media**: Support for raw video+sound, merged video+audio, and audio-only downloads.
- **Conversion**: Convert non-MP4 video formats to MP4 and non-MP3 audio formats to MP3.
- **Progress Monitoring**: Real-time updates on download progress and state.

## Platform Support

- **Android Only**: Utilizes Chaquopy for Python integration, limiting support to Android (minimum SDK 24, Android 7.0+).
- iOS support is not currently implemented.

## Installation

Add the plugin to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_yt_dlp: ^0.1.0
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

## Usage

### Initialize the Plugin

Initialize the plugin in your app’s entry point to set up logging:

```dart
import 'package:flutter_yt_dlp/flutter_yt_dlp.dart';

void main() {
  FlutterYtDlpPlugin.initialize(); // Sets up logging
  runApp(MyApp());
}
```

### Request Permissions

Use the `permission_handler` package to request storage permissions:

```dart
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestStoragePermission() async {
  return await Permission.storage.request().isGranted;
}
```

### Fetch Formats

Retrieve available formats for a URL:

```dart
final url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ";

// Raw video with sound
final rawVideoFormats = await FlutterYtDlpPlugin.getAllRawVideoWithSoundFormats(url);

// Video and audio for merging
final mergeFormats = await FlutterYtDlpPlugin.getRawVideoAndAudioFormatsForMerge(url);

// Non-MP4 video for conversion
final convertVideoFormats = await FlutterYtDlpPlugin.getNonMp4VideoWithSoundFormatsForConversion(url);

// Raw audio-only
final rawAudioFormats = await FlutterYtDlpPlugin.getAllRawAudioOnlyFormats(url);

// Non-MP3 audio for conversion
final convertAudioFormats = await FlutterYtDlpPlugin.getNonMp3AudioOnlyFormatsForConversion(url);
```

### Start a Download

Download a selected format using an app-specific directory:

```dart
import 'package:path_provider/path_provider.dart';

final outputDir = (await getExternalStorageDirectory())!.path;
final format = rawVideoFormats.first; // Example: select the first format
final task = await FlutterYtDlpPlugin.download(
  format: format,
  outputDir: outputDir,
  url: url,
  originalName: "MyVideo",
  overwrite: true,
);

task.progressStream.listen((progress) {
  print("Progress: ${(progress.downloadedBytes / progress.totalBytes * 100).toStringAsFixed(1)}%");
});

task.stateStream.listen((state) {
  print("State: $state");
});
```

### Cancel a Download

Cancel an ongoing download:

```dart
await task.cancel();
```

## Format Types

- **Format**: Base class for audio-only formats, containing `formatId`, `ext`, `resolution`, `bitrate`, and `size`.
- **CombinedFormat**: Extends `Format` for video+sound formats, with a `needsConversion` flag indicating if conversion to MP4 is required.
- **MergeFormat**: Represents separate video and audio formats to be merged into a single MP4 file.

## Example

See the `example/` directory for a complete sample app demonstrating all features, including a UI to test different download types.

## Limitations

- **Android Only**: No iOS support due to the Chaquopy dependency for Python integration.
- **App Size**: Chaquopy and FFmpeg increase APK size significantly. Consider using `flutter build apk --split-per-abi` to reduce size by targeting specific ABIs.
- **Storage Access**: On Android 10+, scoped storage restricts direct access to paths like `/sdcard/Download`. Use `path_provider` to save files in app-specific directories.

## Troubleshooting

- **Permission Denied**: Ensure storage permissions are granted before downloading.
- **No Formats Found**: Verify the URL is valid and supported by yt-dlp.
- **Download Fails**: Check logs (enabled via `FlutterYtDlpPlugin.initialize()`) for detailed error messages.

## Credits

Developed with significant assistance from Grok, created by xAI, which guided the design, implementation, and debugging process.

## License

Licensed under the MIT License. Note that yt-dlp (Unlicense) and FFmpeg (LGPL) have their own licenses, which must be respected in your application.