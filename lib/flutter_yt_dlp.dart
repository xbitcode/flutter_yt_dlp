import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final Logger _logger = Logger('FlutterYtDlpPlugin');

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
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

  DownloadProgress({
    required this.downloadedBytes,
    required this.totalBytes,
  });

  factory DownloadProgress.fromMap(Map<Object?, Object?> map) =>
      DownloadProgress(
        downloadedBytes: map['downloaded'] as int,
        totalBytes: map['total'] as int,
      );
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
    try {
      _logger.info('Fetching all raw video with sound formats for URL: $url');
      final List<dynamic> result = await _channel
          .invokeMethod('getAllRawVideoWithSoundFormats', {'url': url});
      final formats = result
          .map((e) => CombinedFormat.fromMap(e as Map<Object?, Object?>))
          .toList();
      _logger.info('Fetched ${formats.length} raw video+sound formats:');
      for (var format in formats) {
        _logger.info(format.toLogString());
      }
      return formats;
    } on PlatformException catch (e) {
      _logger.severe('Error fetching raw video+sound formats: ${e.message}');
      rethrow;
    }
  }

  static Future<List<MergeFormat>> getRawVideoAndAudioFormatsForMerge(
      String url) async {
    try {
      _logger
          .info('Fetching raw video and audio formats for merge for URL: $url');
      final List<dynamic> result = await _channel
          .invokeMethod('getRawVideoAndAudioFormatsForMerge', {'url': url});
      final formats = result
          .map((e) => MergeFormat.fromMap(e as Map<Object?, Object?>))
          .toList();
      _logger.info('Fetched ${formats.length} merge video+audio formats:');
      for (var format in formats) {
        _logger.info(format.toLogString());
      }
      return formats;
    } on PlatformException catch (e) {
      _logger.severe('Error fetching merge formats: ${e.message}');
      rethrow;
    }
  }

  static Future<List<CombinedFormat>>
      getNonMp4VideoWithSoundFormatsForConversion(String url) async {
    try {
      _logger.info(
          'Fetching non-MP4 video with sound formats for conversion for URL: $url');
      final List<dynamic> result = await _channel.invokeMethod(
          'getNonMp4VideoWithSoundFormatsForConversion', {'url': url});
      final formats = result
          .map((e) => CombinedFormat.fromMap(e as Map<Object?, Object?>))
          .toList();
      _logger.info('Fetched ${formats.length} non-MP4 video+sound formats:');
      for (var format in formats) {
        _logger.info(format.toLogString());
      }
      return formats;
    } on PlatformException catch (e) {
      _logger
          .severe('Error fetching non-MP4 video+sound formats: ${e.message}');
      rethrow;
    }
  }

  static Future<List<Format>> getAllRawAudioOnlyFormats(String url) async {
    try {
      _logger.info('Fetching all raw audio-only formats for URL: $url');
      final List<dynamic> result = await _channel
          .invokeMethod('getAllRawAudioOnlyFormats', {'url': url});
      final formats = result
          .map((e) => Format.fromMap(e as Map<Object?, Object?>))
          .toList();
      _logger.info('Fetched ${formats.length} raw audio-only formats:');
      for (var format in formats) {
        _logger.info(format.toLogString());
      }
      return formats;
    } on PlatformException catch (e) {
      _logger.severe('Error fetching raw audio-only formats: ${e.message}');
      rethrow;
    }
  }

  static Future<List<Format>> getNonMp3AudioOnlyFormatsForConversion(
      String url) async {
    try {
      _logger.info(
          'Fetching non-MP3 audio-only formats for conversion for URL: $url');
      final List<dynamic> result = await _channel
          .invokeMethod('getNonMp3AudioOnlyFormatsForConversion', {'url': url});
      final formats = result
          .map((e) => Format.fromMap(e as Map<Object?, Object?>))
          .toList();
      _logger.info('Fetched ${formats.length} non-MP3 audio-only formats:');
      for (var format in formats) {
        _logger.info(format.toLogString());
      }
      return formats;
    } on PlatformException catch (e) {
      _logger.severe('Error fetching non-MP3 audio-only formats: ${e.message}');
      rethrow;
    }
  }

  static Future<List<dynamic>> getAllVideoWithSoundFormats(String url) async {
    try {
      _logger.info('Fetching all video with sound formats for URL: $url');
      final rawCombined = await getAllRawVideoWithSoundFormats(url);
      final mergeFormats = await getRawVideoAndAudioFormatsForMerge(url);
      final convertFormats =
          await getNonMp4VideoWithSoundFormatsForConversion(url);
      final allFormats = [...rawCombined, ...mergeFormats, ...convertFormats];
      _logger.info('Total video+sound formats fetched: ${allFormats.length}');
      return allFormats;
    } on PlatformException catch (e) {
      _logger.severe('Error fetching all video+sound formats: ${e.message}');
      rethrow;
    }
  }

  static Future<List<Format>> getAllAudioOnlyFormats(String url) async {
    try {
      _logger.info('Fetching all audio-only formats for URL: $url');
      final rawAudio = await getAllRawAudioOnlyFormats(url);
      final convertAudio = await getNonMp3AudioOnlyFormatsForConversion(url);
      final allFormats = [...rawAudio, ...convertAudio];
      _logger.info('Total audio-only formats fetched: ${allFormats.length}');
      return allFormats;
    } on PlatformException catch (e) {
      _logger.severe('Error fetching all audio-only formats: ${e.message}');
      rethrow;
    }
  }

  static String _generateFileName(
      String originalName, String resolution, int bitrate, String ext) {
    final cleanName = originalName.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    return "${cleanName}_${resolution}_${bitrate}kbps.$ext";
  }

  static Future<DownloadTask> download({
    required dynamic format,
    required String outputDir,
    required String url,
    required String originalName,
    bool overwrite = false,
  }) async {
    try {
      _logger
          .info('Starting download for URL: $url with overwrite: $overwrite');
      String outputPath;
      String sizeInfo = '';

      if (format is MergeFormat) {
        outputPath =
            "$outputDir/${_generateFileName(originalName, format.video.resolution, format.audio.bitrate, 'mp4')}";
        sizeInfo =
            'Video: ${format.video.toLogString()} | Audio: ${format.audio.toLogString()}';
      } else if (format is CombinedFormat) {
        final ext = format.needsConversion ? 'mp4' : format.ext;
        outputPath =
            "$outputDir/${_generateFileName(originalName, format.resolution, format.bitrate, ext)}";
        sizeInfo = format.toLogString();
      } else if (format is Format) {
        final ext = format.ext != 'mp3'
            ? 'mp3'
            : format.ext; // Ensure non-MP3 converts to MP3
        outputPath =
            "$outputDir/${_generateFileName(originalName, format.resolution, format.bitrate, ext)}";
        sizeInfo = format.toLogString();
      } else {
        throw ArgumentError('Unsupported format type');
      }

      _logger.info('Format details: $sizeInfo');
      _logger.info('Output path: $outputPath');

      final Map<String, dynamic> formatMap;
      if (format is MergeFormat) {
        formatMap = format.toMap();
      } else if (format is CombinedFormat) {
        formatMap = format.toMap();
      } else if (format is Format) {
        formatMap = format.toMap();
      } else {
        throw ArgumentError('Unsupported format type');
      }

      final String taskId = await _channel.invokeMethod('startDownload', {
        'format': formatMap,
        'outputPath': outputPath,
        'url': url,
        'overwrite': overwrite,
      });
      _logger.info('Download task started with ID: $taskId');

      final progressController = StreamController<DownloadProgress>();
      final stateController = StreamController<DownloadState>();

      // Declare subscription before using it
      late StreamSubscription subscription;
      subscription = _eventChannel.receiveBroadcastStream().listen((event) {
        final map = event as Map<Object?, Object?>;
        if (map['taskId'] == taskId) {
          if (map['type'] == 'progress') {
            final progress =
                DownloadProgress.fromMap(map.cast<String, dynamic>());
            _logger.info(
                'Progress for task $taskId: ${formatBytes(progress.downloadedBytes)} / ${formatBytes(progress.totalBytes)}');
            progressController.add(progress);
          } else if (map['type'] == 'state') {
            final state = DownloadState.values[map['state'] as int];
            _logger.info('State change for task $taskId: ${state.name}');
            stateController.add(state);
            if (state == DownloadState.completed ||
                state == DownloadState.failed ||
                state == DownloadState.canceled) {
              progressController.close();
              stateController.close();
              subscription.cancel();
            }
          }
        }
      });

      Future<void> cancel() async {
        _logger.info('Canceling download task $taskId');
        await _channel.invokeMethod('cancelDownload', {'taskId': taskId});
        progressController.close();
        stateController.close();
        subscription.cancel();
      }

      return DownloadTask(
        taskId: taskId,
        progressStream: progressController.stream,
        stateStream: stateController.stream,
        cancel: cancel,
      );
    } on PlatformException catch (e) {
      _logger.severe('Error starting download: ${e.message}');
      rethrow;
    }
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
}
