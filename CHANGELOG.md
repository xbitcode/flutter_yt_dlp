# Changelog

All notable changes to the `flutter_yt_dlp` plugin will be documented in this file.

## 0.1.0 - 2025-03-12

### Initial Release

- **Added**: Support for fetching media formats using `yt-dlp`:
  - Raw video with sound formats (`getAllRawVideoWithSoundFormats`).
  - Video and audio formats for merging (`getRawVideoAndAudioFormatsForMerge`).
  - Non-MP4 video formats for conversion to MP4 (`getNonMp4VideoWithSoundFormatsForConversion`).
  - Raw audio-only formats (`getAllRawAudioOnlyFormats`).
  - Non-MP3 audio formats for conversion to MP3 (`getNonMp3AudioOnlyFormatsForConversion`).
- **Added**: Download functionality with progress and state tracking:
  - Download raw video+sound, merged video+audio, and audio-only formats.
  - Real-time progress updates via `progressStream`.
  - State updates (preparing, downloading, merging, converting, completed, canceled, failed) via `stateStream`.
  - Option to cancel downloads mid-progress.
- **Added**: Conversion support using FFmpeg:
  - Convert non-MP4 video formats to MP4.
  - Convert non-MP3 audio formats to MP3.
- **Added**: Example app demonstrating all features with a simple UI.
- **Platform**: Android-only support via Chaquopy for Python integration (minimum SDK 24).
- **Dependencies**: Integrated `yt-dlp` (2025.2.19) and FFmpeg (6.0) via Chaquopy.
- **Developed**: With assistance from Grok by xAI for design and implementation.

## 0.0.1

- Placeholder for initial development version (not released).
