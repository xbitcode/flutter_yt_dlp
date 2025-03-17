# flutter_yt_dlp

A Flutter plugin for downloading and processing media using `yt-dlp` and FFmpeg.

## Features

- Fetch video metadata, including title, thumbnail, and categorized formats.
- Categorize formats into:
  - **Raw Video with Sound**: Combined video and audio formats, convertible to MP4 if not already.
  - **Merge Formats**: Video-only formats paired with suitable audio-only formats, merged into MP4.
  - **Raw Audio-Only**: Audio-only formats, convertible to MP3 if not already.
- Download media with progress and state updates via streams.
- Support for cancellation and custom output directories.
- Compatible with Android legacy and scoped storage.

## Getting Started

1. Add the plugin to your `pubspec.yaml`:

[TRIPLE_BACKTICKS]yaml
dependencies:
  flutter_yt_dlp: ^0.2.0
[TRIPLE_BACKTICKS]

2. Import the plugin:

[TRIPLE_BACKTICKS]dart
import 'package:flutter_yt_dlp/flutter_yt_dlp.dart';
[TRIPLE_BACKTICKS]

3. Initialize the client:

[TRIPLE_BACKTICKS]dart
final client = FlutterYtDlpClient();
[TRIPLE_BACKTICKS]

4. Fetch video info:

[TRIPLE_BACKTICKS]dart
final info = await client.getVideoInfo('<https://youtube.com/watch?v=video_id>');
[TRIPLE_BACKTICKS]

5. Get categorized formats:

[TRIPLE_BACKTICKS]dart
final combined = await client.getCombinedFormats('<https://youtube.com/watch?v=video_id>');
final merge = await client.getMergeFormats('<https://youtube.com/watch?v=video_id>');
final audio = await client.getAudioOnlyFormats('<https://youtube.com/watch?v=video_id>');
[TRIPLE_BACKTICKS]

6. Start a download:

[TRIPLE_BACKTICKS]dart
final taskId = await client.startDownload(
  format: info['rawVideoWithSoundFormats'][0],
  outputDir: '/storage/emulated/0/Download',
  url: '<https://youtube.com/watch?v=video_id>',
  overwrite: false,
);
[TRIPLE_BACKTICKS]

7. Listen to download events:

[TRIPLE_BACKTICKS]dart
client.getDownloadEvents().listen((event) {
  if (event['type'] == 'progress') {
    print('Progress: ${event['downloaded']} / ${event['total']}');
  } else if (event['type'] == 'state') {
    print('State: ${event['stateName']}');
  }
});
[TRIPLE_BACKTICKS]

8. Cancel a download:

[TRIPLE_BACKTICKS]dart
await client.cancelDownload(taskId);
[TRIPLE_BACKTICKS]

## Format Categories

- **Raw Video with Sound**: Formats with both video and audio. Non-MP4 formats include a `needsConversion` flag.
- **Merge Formats**: Video-only formats paired with a high-bitrate audio-only format, merged to MP4.
- **Raw Audio-Only**: Audio-only formats. Non-MP3 formats include a `needsConversion` flag.

## Example

See the `example` directory for a complete demo app.

## Dependencies

- FFmpeg: `com.arthenica:ffmpeg-kit-full:6.0`
- yt-dlp: `2025.2.19`
