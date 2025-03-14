import 'dart:async';
import 'package:logging/logging.dart'; // Add this import for logging

/// Base class representing a media format with metadata.
///
/// This class holds information about a media format, such as its ID, extension,
/// resolution, bitrate, and size. Fields like [formatId], [ext], and [resolution]
/// are nullable to handle cases where data might be missing from the source.
class Format {
  /// The unique identifier for the format.
  final String? formatId;

  /// The file extension of the format.
  final String? ext;

  /// The resolution of the format (e.g., "256x144" or "audio only").
  final String? resolution;

  /// The bitrate of the format in kilobits per second (kbps).
  final int bitrate;

  /// The size of the format in bytes.
  final int size;

  Format({
    this.formatId,
    this.ext,
    this.resolution,
    required this.bitrate,
    required this.size,
  });

  /// Converts the format to a map for serialization.
  Map<String, dynamic> toMap() => {
        'formatId': formatId,
        'ext': ext,
        'resolution': resolution,
        'bitrate': bitrate,
        'size': size,
      };

  /// Creates a [Format] instance from a map.
  factory Format.fromMap(Map<dynamic, dynamic> map) => Format(
        formatId: map['formatId'] as String? ?? 'unknown',
        ext: map['ext'] as String? ?? 'unknown',
        resolution: map['resolution'] as String? ?? 'unknown',
        bitrate: map['bitrate'] as int? ?? 0,
        size: map['size'] as int? ?? 0,
      );

  /// Returns a string representation of the format for logging.
  String toLogString(String Function(int) formatBytes) =>
      'Format ID: ${formatId ?? "unknown"}, Ext: ${ext ?? "unknown"}, Resolution: ${resolution ?? "unknown"}, Bitrate: $bitrate kbps, Size: ${formatBytes(size)}';
}

/// A format combining video and audio, with an option for conversion.
///
/// Extends [Format] to include a flag indicating whether the format needs
/// conversion (e.g., to MP4).
class CombinedFormat extends Format {
  /// Indicates if the format requires conversion.
  final bool needsConversion;

  CombinedFormat({
    super.formatId,
    super.ext,
    super.resolution,
    required super.bitrate,
    required super.size,
    required this.needsConversion,
  });

  @override
  Map<String, dynamic> toMap() => {
        ...super.toMap(),
        'needsConversion': needsConversion,
        'type': 'combined',
      };

  /// Creates a [CombinedFormat] instance from a map.
  factory CombinedFormat.fromMap(Map<dynamic, dynamic> map) => CombinedFormat(
        formatId: map['formatId'] as String? ?? 'unknown',
        ext: map['ext'] as String? ?? 'unknown',
        resolution: map['resolution'] as String? ?? 'unknown',
        bitrate: map['bitrate'] as int? ?? 0,
        size: map['size'] as int? ?? 0,
        needsConversion: map['needsConversion'] as bool? ?? false,
      );

  @override
  String toLogString(String Function(int) formatBytes) =>
      '${super.toLogString(formatBytes)}, Needs Conversion: $needsConversion';
}

/// Represents a pair of video and audio formats to be merged into a single file.
class MergeFormat {
  /// The video format component.
  final Format video;

  /// The audio format component.
  final Format audio;

  // Define logger here, matching the setup in flutter_yt_dlp.dart
  static final Logger _logger = Logger('FlutterYtDlpPlugin');

  MergeFormat({required this.video, required this.audio});

  /// Converts the merge format to a map for serialization.
  Map<String, dynamic> toMap() => {
        'video': video.toMap(),
        'audio': audio.toMap(),
        'type': 'merge',
      };

  /// Creates a [MergeFormat] instance from a map.
  factory MergeFormat.fromMap(Map<dynamic, dynamic> map) {
    _logger.info('Raw map input to MergeFormat: $map'); // Debug log
    final videoMap =
        (map['video'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ?? {};
    final audioMap =
        (map['audio'] as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ?? {};
    _logger.info('Video map: $videoMap'); // Debug log
    _logger.info('Audio map: $audioMap'); // Debug log
    return MergeFormat(
      video: Format.fromMap(videoMap),
      audio: Format.fromMap(audioMap),
    );
  }

  /// Returns a string representation of the merge format for logging.
  String toLogString(String Function(int) formatBytes) =>
      'Video: ${video.toLogString(formatBytes)}, Audio: ${audio.toLogString(formatBytes)}';
}

/// Represents progress information for a download.
class DownloadProgress {
  /// The number of bytes downloaded.
  final int downloadedBytes;

  /// The total number of bytes to download.
  final int totalBytes;

  DownloadProgress({required this.downloadedBytes, required this.totalBytes});

  /// Creates a [DownloadProgress] instance from a map.
  factory DownloadProgress.fromMap(Map<dynamic, dynamic> map) =>
      DownloadProgress(
        downloadedBytes: map['downloaded'] as int? ?? 0,
        totalBytes: map['total'] as int? ?? 0,
      );

  /// Calculates the download progress percentage.
  double get percentage => totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;
}

/// States a download task can be in.
enum DownloadState {
  preparing,
  downloading,
  merging,
  converting,
  completed,
  canceled,
  failed,
}

/// Manages a download task with progress and state streams.
///
/// Provides streams to monitor download progress and state, and a method to cancel
/// the download.
class DownloadTask {
  /// The unique identifier for the download task.
  final String taskId;

  /// Stream of download progress updates.
  final Stream<DownloadProgress> progressStream;

  /// Stream of download state updates.
  final Stream<DownloadState> stateStream;

  /// Function to cancel the download task.
  final Future<void> Function() cancel;

  /// The output path where the downloaded file will be saved.
  final String outputPath;

  DownloadTask({
    required this.taskId,
    required this.progressStream,
    required this.stateStream,
    required this.cancel,
    required this.outputPath,
  });
}
