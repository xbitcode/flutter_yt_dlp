import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('FlutterYtDlpPlugin');

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}

class Format {
  final String formatId;
  final String ext;
  final String resolution;
  final int bitrate;
  final int size;

  Format({
    required this.formatId,
    required this.ext,
    required this.resolution,
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

  factory Format.fromMap(Map<Object?, Object?> map) => Format(
        formatId: map['formatId'] as String,
        ext: map['ext'] as String,
        resolution: map['resolution'] as String,
        bitrate: map['bitrate'] as int,
        size: map['size'] as int,
      );

  String toLogString() =>
      'Format ID: $formatId, Ext: $ext, Resolution: $resolution, Bitrate: $bitrate kbps, Size: ${FlutterYtDlpPlugin.formatBytes(size)}';
}

class CombinedFormat extends Format {
  final bool needsConversion;

  CombinedFormat({
    required super.formatId,
    required super.ext,
    required super.resolution,
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

  factory CombinedFormat.fromMap(Map<Object?, Object?> map) => CombinedFormat(
        formatId: map['formatId'] as String,
        ext: map['ext'] as String,
        resolution: map['resolution'] as String,
        bitrate: map['bitrate'] as int,
        size: map['size'] as int,
        needsConversion: map['needsConversion'] as bool,
      );

  @override
  String toLogString() =>
      '${super.toLogString()}, Needs Conversion: $needsConversion';
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

  factory MergeFormat.fromMap(Map<Object?, Object?> map) => MergeFormat(
        video: Format.fromMap(map['video'] as Map<Object?, Object?>),
        audio: Format.fromMap(map['audio'] as Map<Object?, Object?>),
      );

  String toLogString() =>
      'Video: ${video.toLogString()}, Audio: ${audio.toLogString()}';
}

class DownloadProgress {
  final int downloadedBytes;
  final int totalBytes;

  DownloadProgress({required this.downloadedBytes, required this.totalBytes});

  factory DownloadProgress.fromMap(Map<Object?, Object?> map) =>
      DownloadProgress(
        downloadedBytes: map['downloaded'] as int,
        totalBytes: map['total'] as int,
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

  DownloadTask({
    required this.taskId,
    required this.progressStream,
    required this.stateStream,
    required this.cancel,
  });
}

class FlutterYtDlpPlugin {
  static const MethodChannel _channel = MethodChannel('flutter_yt_dlp');
  static const EventChannel _eventChannel =
      EventChannel('flutter_yt_dlp/events');

  static void initialize() {
    _setupLogging();
    _logger.info('FlutterYtDlpPlugin initialized');
  }

  static Future<List<CombinedFormat>> getAllRawVideoWithSoundFormats(
      String url) async {
    final result = await _fetchFormats('getAllRawVideoWithSoundFormats', url);
    return result.map((e) => CombinedFormat.fromMap(e)).toList();
  }

  static Future<List<MergeFormat>> getRawVideoAndAudioFormatsForMerge(
      String url) async {
    final result =
        await _fetchFormats('getRawVideoAndAudioFormatsForMerge', url);
    return result.map((e) => MergeFormat.fromMap(e)).toList();
  }

  static Future<List<CombinedFormat>>
      getNonMp4VideoWithSoundFormatsForConversion(String url) async {
    final result =
        await _fetchFormats('getNonMp4VideoWithSoundFormatsForConversion', url);
    return result.map((e) => CombinedFormat.fromMap(e)).toList();
  }

  static Future<List<Format>> getAllRawAudioOnlyFormats(String url) async {
    final result = await _fetchFormats('getAllRawAudioOnlyFormats', url);
    return result.map((e) => Format.fromMap(e)).toList();
  }

  static Future<List<Format>> getNonMp3AudioOnlyFormatsForConversion(
      String url) async {
    final result =
        await _fetchFormats('getNonMp3AudioOnlyFormatsForConversion', url);
    return result.map((e) => Format.fromMap(e)).toList();
  }

  static Future<List<dynamic>> getAllVideoWithSoundFormats(String url) async {
    final rawCombined = await getAllRawVideoWithSoundFormats(url);
    final mergeFormats = await getRawVideoAndAudioFormatsForMerge(url);
    final convertFormats =
        await getNonMp4VideoWithSoundFormatsForConversion(url);
    return [...rawCombined, ...mergeFormats, ...convertFormats];
  }

  static Future<List<Format>> getAllAudioOnlyFormats(String url) async {
    final rawAudio = await getAllRawAudioOnlyFormats(url);
    final convertAudio = await getNonMp3AudioOnlyFormatsForConversion(url);
    return [...rawAudio, ...convertAudio];
  }

  static Future<DownloadTask> download({
    required dynamic format,
    required String outputDir,
    required String url,
    required String originalName,
    bool overwrite = false,
  }) async {
    final outputPath = _generateOutputPath(format, outputDir, originalName);
    final formatMap = _convertFormatToMap(format);
    final taskId = await _startDownload(formatMap, outputPath, url, overwrite);
    return _createDownloadTask(taskId);
  }

  static String formatBytes(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = bytes.toDouble();
    int unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(2)} ${units[unitIndex]}';
  }

  static Future<List<dynamic>> _fetchFormats(String method, String url) async {
    try {
      _logger.info('Fetching $method for URL: $url');
      final result = await _channel.invokeMethod(method, {'url': url});
      final formats = (result as List<dynamic>).cast<Map<Object?, Object?>>();
      _logger.info('Fetched ${formats.length} formats');
      formats.forEach((f) => _logger.info(_formatToLogString(f)));
      return formats;
    } on PlatformException catch (e) {
      _logger.severe('Error fetching $method: ${e.message}');
      rethrow;
    }
  }

  static String _generateOutputPath(
      dynamic format, String outputDir, String originalName) {
    final cleanName = originalName.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    if (format is MergeFormat) {
      return "$outputDir/${cleanName}_${format.video.resolution}_${format.audio.bitrate}kbps.mp4";
    } else if (format is CombinedFormat) {
      final ext = format.needsConversion ? 'mp4' : format.ext;
      return "$outputDir/${cleanName}_${format.resolution}_${format.bitrate}kbps.$ext";
    } else if (format is Format) {
      final ext = format.ext != 'mp3' ? 'mp3' : format.ext;
      return "$outputDir/${cleanName}_${format.resolution}_${format.bitrate}kbps.$ext";
    }
    throw ArgumentError('Unsupported format type');
  }

  static Map<String, dynamic> _convertFormatToMap(dynamic format) {
    if (format is MergeFormat) return format.toMap();
    if (format is CombinedFormat) return format.toMap();
    if (format is Format) return format.toMap();
    throw ArgumentError('Unsupported format type');
  }

  static Future<String> _startDownload(
    Map<String, dynamic> formatMap,
    String outputPath,
    String url,
    bool overwrite,
  ) async {
    try {
      _logger.info('Starting download for URL: $url to $outputPath');
      return await _channel.invokeMethod('startDownload', {
        'format': formatMap,
        'outputPath': outputPath,
        'url': url,
        'overwrite': overwrite,
      }) as String;
    } on PlatformException catch (e) {
      _logger.severe('Error starting download: ${e.message}');
      rethrow;
    }
  }

  static DownloadTask _createDownloadTask(String taskId) {
    final progressController = StreamController<DownloadProgress>.broadcast();
    final stateController = StreamController<DownloadState>.broadcast();

    late StreamSubscription subscription;
    subscription = _eventChannel.receiveBroadcastStream().listen((event) {
      final map = event as Map<Object?, Object?>;
      if (map['taskId'] != taskId) return;
      if (map['type'] == 'progress') {
        final progress = DownloadProgress.fromMap(map.cast<String, dynamic>());
        progressController.add(progress);
      } else if (map['type'] == 'state') {
        final state = DownloadState.values[map['state'] as int];
        stateController.add(state);
        if (state == DownloadState.completed ||
            state == DownloadState.failed ||
            state == DownloadState.canceled) {
          progressController.close();
          stateController.close();
          subscription.cancel();
        }
      }
    });

    Future<void> cancelDownload() async {
      try {
        _logger.info('Canceling download task $taskId');
        await _channel.invokeMethod('cancelDownload', {'taskId': taskId});
        progressController
            .add(DownloadProgress(downloadedBytes: 0, totalBytes: 0));
        stateController.add(DownloadState.canceled);
        await subscription.cancel();
      } on PlatformException catch (e) {
        _logger.severe('Failed to cancel download task $taskId: ${e.message}');
        rethrow;
      }
    }

    return DownloadTask(
      taskId: taskId,
      progressStream: progressController.stream,
      stateStream: stateController.stream,
      cancel: cancelDownload,
    );
  }

  static String _formatToLogString(Map<Object?, Object?> format) {
    if (format['type'] == 'merge') {
      return MergeFormat.fromMap(format).toLogString();
    } else if (format['type'] == 'combined') {
      return CombinedFormat.fromMap(format).toLogString();
    }
    return Format.fromMap(format).toLogString();
  }
}
