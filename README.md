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