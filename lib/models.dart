import 'logger.dart';

class Format {
  final String? formatId;
  final String? ext;
  final String? resolution;
  final int bitrate;
  final int size;

  Format({
    this.formatId,
    this.ext,
    this.resolution,
    required this.bitrate,
    required this.size,
  });

  Map<String, dynamic> toMap() => {
        'formatId': formatId,
        'ext': ext,
        'resolution': resolution,
        'bitrate': bitrate,
        'size': size,
      };

  factory Format.fromMap(Map<dynamic, dynamic> map) => Format(
        formatId: map['formatId'] as String? ?? 'unknown',
        ext: map['ext'] as String? ?? 'unknown',
        resolution: map['resolution'] as String? ?? 'unknown',
        bitrate: map['bitrate'] as int? ?? 0,
        size: map['size'] as int? ?? 0,
      );

  String toLogString(String Function(int) formatBytes) =>
      'Format ID: ${formatId ?? "unknown"}, Ext: ${ext ?? "unknown"}, Resolution: ${resolution ?? "unknown"}, Bitrate: $bitrate kbps, Size: ${formatBytes(size)}';
}

class CombinedFormat extends Format {
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

class MergeFormat {
  final Format video;
  final Format audio;

  MergeFormat({required this.video, required this.audio});

  Map<String, dynamic> toMap() => {
        'video': video.toMap(),
        'audio': audio.toMap(),
        'type': 'merge',
      };

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

  String toLogString(String Function(int) formatBytes) =>
      'Video: ${video.toLogString(formatBytes)}, Audio: ${audio.toLogString(formatBytes)}';
}

class DownloadProgress {
  final int downloadedBytes;
  final int totalBytes;

  DownloadProgress({required this.downloadedBytes, required this.totalBytes});

  factory DownloadProgress.fromMap(Map<dynamic, dynamic> map) =>
      DownloadProgress(
        downloadedBytes: map['downloaded'] as int? ?? 0,
        totalBytes: map['total'] as int? ?? 0,
      );

  double get percentage => totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;
}

enum DownloadState {
  preparing,
  downloading,
  merging,
  converting,
  completed,
  canceled,
  failed,
}

class DownloadTask {
  final String taskId;
  final Stream<DownloadProgress> progressStream;
  final Stream<DownloadState> stateStream;
  final Future<void> Function() cancel;
  final String outputPath;

  DownloadTask({
    required this.taskId,
    required this.progressStream,
    required this.stateStream,
    required this.cancel,
    required this.outputPath,
  });
}
