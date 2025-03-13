// C:\Users\Abdullah\flutter_apps_temp\flutter_yt_dlp\lib\models.dart
import 'dart:async';

/// Base class representing a media format with metadata.
///
/// This class holds information about a media format, such as its ID, extension,
/// resolution, bitrate, and size. Fields like [formatId], [ext], and [resolution]
/// are nullable to handle cases where data might be missing from the source.
class Format {
  /// The unique identifier for the format, or null if unknown.
  final String? formatId;

  /// The file extension of the format (e.g., 'mp4', 'mp3'), or null if unknown.
  final String? ext;

  /// The resolution of the format (e.g., '1920x1080' or 'audio only'), or null if unknown.
  final String? resolution;

  /// The bitrate of the format in kilobits per second (kbps).
  final int bitrate;

  /// The estimated file size in bytes.
  final int size;

  /// Creates a new [Format] instance.
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

  /// Creates a [Format] from a map, providing defaults for null values.
  factory Format.fromMap(Map<Object?, Object?> map) => Format(
        formatId: map['formatId'] as String? ?? 'unknown',
        ext: map['ext'] as String? ?? 'unknown',
        resolution: map['resolution'] as String? ?? 'unknown',
        bitrate: map['bitrate'] as int? ?? 0,
        size: map['size'] as int? ?? 0,
      );

  /// Returns a string representation for logging purposes.
  String toLogString(String Function(int) formatBytes) =>
      'Format ID: ${formatId ?? "unknown"}, Ext: ${ext ?? "unknown"}, Resolution: ${resolution ?? "unknown"}, Bitrate: $bitrate kbps, Size: ${formatBytes(size)}';
}

/// A format combining video and audio, with an option for conversion.
///
/// Extends [Format] to include a flag indicating whether the format needs
/// conversion (e.g., to MP4).
class CombinedFormat extends Format {
  /// Indicates if this format requires conversion to a standard format (e.g., MP4).
  final bool needsConversion;

  /// Creates a new [CombinedFormat] instance.
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

  /// Creates a [CombinedFormat] from a map, providing defaults for null values.
  factory CombinedFormat.fromMap(Map<Object?, Object?> map) => CombinedFormat(
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

  /// Creates a new [MergeFormat] instance.
  MergeFormat({required this.video, required this.audio});

  /// Converts the merge format to a map for serialization.
  Map<String, dynamic> toMap() => {
        'video': video.toMap(),
        'audio': audio.toMap(),
        'type': 'merge',
      };

  /// Creates a [MergeFormat] from a map.
  factory MergeFormat.fromMap(Map<Object?, Object?> map) => MergeFormat(
        video: Format.fromMap(map['video'] as Map<Object?, Object?>),
        audio: Format.fromMap(map['audio'] as Map<Object?, Object?>),
      );

  /// Returns a string representation for logging purposes.
  String toLogString(String Function(int) formatBytes) =>
      'Video: ${video.toLogString(formatBytes)}, Audio: ${audio.toLogString(formatBytes)}';
}

/// Represents progress information for a download.
class DownloadProgress {
  /// The number of bytes downloaded so far.
  final int downloadedBytes;

  /// The total number of bytes to download.
  final int totalBytes;

  /// Creates a new [DownloadProgress] instance.
  DownloadProgress({required this.downloadedBytes, required this.totalBytes});

  /// Creates a [DownloadProgress] from a map, providing defaults for null values.
  factory DownloadProgress.fromMap(Map<Object?, Object?> map) =>
      DownloadProgress(
        downloadedBytes: map['downloaded'] as int? ?? 0,
        totalBytes: map['total'] as int? ?? 0,
      );

  /// The percentage of the download completed (0.0 to 1.0).
  double get percentage => totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;
}

/// States a download task can be in.
enum DownloadState {
  /// Preparing to start the download.
  preparing,

  /// Actively downloading the media.
  downloading,

  /// Merging video and audio streams.
  merging,

  /// Converting the media format.
  converting,

  /// Download completed successfully.
  completed,

  /// Download was canceled by the user.
  canceled,

  /// Download failed due to an error.
  failed,
}

/// Manages a download task with progress and state streams.
///
/// Provides streams to monitor download progress and state, and a method to cancel
/// the download.
class DownloadTask {
  /// The unique identifier for this download task.
  final String taskId;

  /// Stream emitting progress updates as the download proceeds.
  final Stream<DownloadProgress> progressStream;

  /// Stream emitting state changes during the download process.
  final Stream<DownloadState> stateStream;

  /// Cancels the download task and cleans up resources.
  final Future<void> Function() cancel;

  /// The full path where the downloaded file will be saved.
  final String outputPath;

  /// Creates a new [DownloadTask] instance.
  DownloadTask({
    required this.taskId,
    required this.progressStream,
    required this.stateStream,
    required this.cancel,
    required this.outputPath,
  });
}
