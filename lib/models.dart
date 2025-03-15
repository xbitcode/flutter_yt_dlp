import 'logger.dart';

/// Represents a media format with basic properties.
class Format {
  /// Unique identifier for the format.
  final String? formatId;

  /// File extension (e.g., 'mp4', 'mp3').
  final String? ext;

  /// Resolution (e.g., '1920x1080').
  final String? resolution;

  /// Bitrate in kbps.
  final int bitrate;

  /// Size in bytes.
  final int size;

  /// Creates a [Format] instance.
  Format({
    this.formatId,
    this.ext,
    this.resolution,
    required this.bitrate,
    required this.size,
  });

  /// Converts the format to a map.
  Map<String, dynamic> toMap() => {
        'formatId': formatId,
        'ext': ext,
        'resolution': resolution,
        'bitrate': bitrate,
        'size': size,
        'type': FormatTypes.audioOnly,
      };

  /// Creates a [Format] from a map.
  factory Format.fromMap(Map<dynamic, dynamic> map) => Format(
        formatId: map['formatId'] as String? ?? 'unknown',
        ext: map['ext'] as String? ?? 'unknown',
        resolution: map['resolution'] as String? ?? 'unknown',
        bitrate: map['bitrate'] as int? ?? 0,
        size: map['size'] as int? ?? 0,
      );

  /// Returns a string representation for logging.
  String toLogString(String Function(int) formatBytes) =>
      'Format ID: ${formatId ?? "unknown"}, Ext: ${ext ?? "unknown"}, Resolution: ${resolution ?? "unknown"}, Bitrate: $bitrate kbps, Size: ${formatBytes(size)}';
}

/// Represents a format that combines video and audio, with conversion option.
class CombinedFormat extends Format {
  /// Indicates if conversion is needed (e.g., to mp4 or mp3).
  final bool needsConversion;

  /// Creates a [CombinedFormat] instance.
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
        'type': FormatTypes.videoWithSound,
      };

  /// Creates a [CombinedFormat] from a map.
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

/// Represents a format requiring video and audio merging.
class MergeFormat {
  /// Video-only format.
  final Format video;

  /// Audio-only format.
  final Format audio;

  /// Creates a [MergeFormat] instance.
  MergeFormat({required this.video, required this.audio});

  /// Converts the merge format to a map.
  Map<String, dynamic> toMap() => {
        'video': video.toMap(),
        'audio': audio.toMap(),
        'type': FormatTypes.merge,
      };

  /// Creates a [MergeFormat] from a map.
  factory MergeFormat.fromMap(Map<dynamic, dynamic> map) {
    final videoMap = map['video']?.cast<String, dynamic>() ?? {};
    final audioMap = map['audio']?.cast<String, dynamic>() ?? {};
    PluginLogger.info(
        'Parsing MergeFormat - Video: $videoMap, Audio: $audioMap');
    return MergeFormat(
      video: Format.fromMap(videoMap),
      audio: Format.fromMap(audioMap),
    );
  }

  /// Returns a string representation for logging.
  String toLogString(String Function(int) formatBytes) =>
      'Video: ${video.toLogString(formatBytes)}, Audio: ${audio.toLogString(formatBytes)}';
}

/// Defines constants for format types.
class FormatTypes {
  /// Video with embedded audio.
  static const String videoWithSound = 'video_with_sound';

  /// Separate video and audio to merge.
  static const String merge = 'merge';

  /// Audio-only format.
  static const String audioOnly = 'audio_only';
}

/// Tracks download progress.
class DownloadProgress {
  /// Bytes downloaded so far.
  final int downloadedBytes;

  /// Total bytes to download.
  final int totalBytes;

  /// Creates a [DownloadProgress] instance.
  DownloadProgress({required this.downloadedBytes, required this.totalBytes});

  /// Creates a [DownloadProgress] from a map.
  factory DownloadProgress.fromMap(Map<dynamic, dynamic> map) =>
      DownloadProgress(
        downloadedBytes: map['downloaded'] as int? ?? 0,
        totalBytes: map['total'] as int? ?? 0,
      );

  /// Calculates the download percentage.
  double get percentage => totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;
}

/// Defines possible states of a download.
enum DownloadState {
  /// Preparing the download.
  preparing,

  /// Actively downloading.
  downloading,

  /// Merging video and audio streams.
  merging,

  /// Converting the file format.
  converting,

  /// Download completed successfully.
  completed,

  /// Download was canceled by the user.
  canceled,

  /// Download failed due to an error.
  failed,
}

/// Represents a download task with streams and cancellation.
class DownloadTask {
  /// Unique identifier for the task.
  final String taskId;

  /// Stream of download progress updates.
  final Stream<DownloadProgress> progressStream;

  /// Stream of download state updates.
  final Stream<DownloadState> stateStream;

  /// Function to cancel the download.
  final Future<void> Function() cancel;

  /// Path where the file will be saved.
  final String outputPath;

  /// Creates a [DownloadTask] instance.
  DownloadTask({
    required this.taskId,
    required this.progressStream,
    required this.stateStream,
    required this.cancel,
    required this.outputPath,
  });
}
