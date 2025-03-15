# Changelog

All notable changes to the `flutter_yt_dlp` plugin will be documented in this file.

## [0.2.0] - 2025-03-14

### Added

- **API Refactor**: Replaced `FlutterYtDlpPlugin` with `FlutterYtDlpClient`, introducing an instance-based API:
  - `getVideoInfo`: Unified method replacing specific format-fetching methods.
  - `getThumbnailUrl`: New method for fetching thumbnails.
  - `startDownload`: Simplified download method with task ID return.
  - `cancelDownload`: Updated to use task IDs.
  - `getDownloadEvents`: Stream-based event handling for progress and state.
- **Format Categorization**: Added `format_categorizer.dart` to handle format categorization on the Dart side.
- **Modular Android Backend**: Split Android logic into multiple Kotlin files (`ChannelManager.kt`, `DownloadManager.kt`, `DownloadProcessor.kt`, `DownloadState.kt`, `FileProcessor.kt`, `JsonParser.kt`, `MethodHandler.kt`, `ProgressTracker.kt`, `VideoInfoFetcher.kt`) for better separation of concerns.
- **Enhanced Example App**: Added a fully functional example app with UI components (`app.dart`, `download_manager.dart`, `download_provider.dart`, `ui/download_controls.dart`, `ui/download_screen.dart`, `ui/format_selector.dart`, `ui/url_input.dart`), showcasing the new API, format selection (raw or converted), and download management.
- **Raw vs. Converted Download Option**: Backend support for `downloadAsRaw`, allowing downloads in raw formats or converted to mp4 (video) or mp3 (audio-only), demonstrated in the example app.
- **Video-Only and Audio-Only Merging**: Backend support for merging video-only and audio-only formats into mp4, enhancing format diversity.

### Changed

- **Breaking Change**: Refactored Dart API from static `FlutterYtDlpPlugin` methods to instance-based `FlutterYtDlpClient`, requiring users to update their code.
- Updated `README.md` to reflect the new API, emphasize raw vs. converted downloads (mp4/mp3), and highlight merging of video-only and audio-only formats.
- Improved download state management and progress tracking in the Android backend, reflected in the example app’s UI via event streams.
- Removed `formatBytes` as a public method (still available internally in the example).

### Fixed

- No specific bugs fixed; focus was on refactoring and feature enhancements.

### Notes

- File sizes remain under 100 lines, and functions average around 3 lines, maintaining clean code principles.
- The use of `print` in `setupLogging` and `initialize()` remains temporary and will be reverted to proper logging in a future release to adhere to `avoid_print` lint rules.

## [0.1.4] - 2025-03-13

### Added

- Expanded Android NDK ABI support in `android/build.gradle` to include `armeabi-v7a`, `arm64-v8a`, `x86`, and `x86_64`, enhancing compatibility across a wider range of devices.
- Added try-catch block in `FlutterYtDlpPlugin.initialize()` to handle and report initialization errors, improving debugging capabilities.
- Added `changed_files.txt` and `old_codebase.txt` to `.gitignore` for better management of temporary development files.

### Changed

- Modified `setupLogging` in `utils.dart` to use `print` instead of `_logger.info` for log output.
- Updated `FlutterYtDlpPlugin.initialize()` to use `print` statements for initialization feedback instead of logging.

### Fixed

- No specific bugs fixed in this release; focus was on compatibility and debugging enhancements.

### Notes

- The use of `print` in `setupLogging` and `initialize()` is temporary and will be reverted to proper logging in the next release to adhere to `avoid_print` lint rules.
- File sizes remain under 100 lines, and functions average around 3 lines, maintaining clean code principles.

## [0.1.3] - 2025-03-13

### Added

- Split `flutter_yt_dlp.dart` into three files for improved maintainability:
  - `models.dart`: Contains data classes (`Format`, `CombinedFormat`, `MergeFormat`, `DownloadProgress`, `DownloadState`, `DownloadTask`).
  - `utils.dart`: Contains utility functions (`setupLogging`, `generateOutputPath`, `convertFormatToMap`).
  - `flutter_yt_dlp.dart`: Main plugin class with core functionality, including `formatBytes`.
- Added comprehensive Dartdoc comments to public APIs to address `public_member_api_docs` lint warnings.
- Exposed `formatBytes` as a public method in `FlutterYtDlpPlugin` for formatting byte sizes in a human-readable format.
- **Improved Null Safety**: Updated `Format`, `CombinedFormat`, and related classes to handle `null` values from platform channels, preventing type cast errors (e.g., `TypeError: type 'Null' is not a subtype of type 'String'`).

### Changed

- Updated `toLogString` methods in `models.dart` to use `String Function(int)` syntax for better type safety.
- Adjusted imports in `main.dart` to reflect the new modular file structure.
- Improved logging in `_fetchFormats` to use a ternary operator for format type checking.
- Renamed `_MyAppState` to `MyAppState` in `main.dart` to resolve `library_private_types_in_public_api`.

### Fixed

- Resolved `undefined_method: formatBytes` errors in `main.dart` by making `formatBytes` a public method in `FlutterYtDlpPlugin`.
- Fixed `undefined_identifier` errors in `utils.dart` by adding `import 'models.dart'`.
- Replaced `print` with logging in `setupLogging` to fix `avoid_print` lint warning.
- Corrected `forEach` usage in `_fetchFormats` to a `for` loop to address `avoid_function_literals_in_foreach_calls`.

### Notes

- File sizes are kept under 100 lines each, with functions averaging around 3 lines, adhering to clean code principles.
- Some `public_member_api_docs` warnings remain but are informational (severity 2).

## [0.1.2] - 2025-03-13

### Changed

- Removed unnecessary comments for cleaner and more maintainable code.

## [0.1.1] - 2025-03-12

### Added

- **Cancel Download Refinement**: Enhanced the `DownloadTask.cancel()` method with better stream cleanup and state management, ensuring robust cancellation of ongoing downloads.

## [0.1.0] - 2025-03-12

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
- **Added**: Example app demonstrating all features with a simple UI.
- **Platform**: Android-only support via Chaquopy for Python integration (minimum SDK 24).
- **Dependencies**: Integrated `yt-dlp` (2025.2.19) and FFmpeg (6.0) via Chaquopy.
- **Developed**: With assistance from Grok by xAI for design and implementation.

## [0.0.1]

- Placeholder for initial development version (not released).
