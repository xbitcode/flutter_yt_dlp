export 'models.dart';
export 'utils.dart';

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'models.dart';
import 'utils.dart';

/// A Flutter plugin for downloading and processing media using yt-dlp and FFmpeg.
class FlutterYtDlpPlugin {
  static const MethodChannel _channel = MethodChannel('flutter_yt_dlp');
  static const EventChannel _eventChannel =
      EventChannel('flutter_yt_dlp/events');
  static final Logger _logger = Logger('FlutterYtDlpPlugin');

  /// Initializes the plugin by setting up logging.
  static void initialize() {
    try {
      setupLogging();
      print('FlutterYtDlpPlugin initialized');
    } catch (e) {
      print('Error in FlutterYtDlpPlugin initialization: $e');
    }
  }

  /// Fetches all raw video formats with sound.
  static Future<List<CombinedFormat>> getAllRawVideoWithSoundFormats(
      String url) async {
    final result = await _fetchFormats('getAllRawVideoWithSoundFormats', url);
    return result
        .where((e) => e['type'] == 'combined' || e['needsConversion'] != null)
        .map((e) => CombinedFormat.fromMap(e))
        .toList();
  }

  /// Fetches raw video and audio formats for merging.
  static Future<List<MergeFormat>> getRawVideoAndAudioFormatsForMerge(
      String url) async {
    final result =
        await _fetchFormats('getRawVideoAndAudioFormatsForMerge', url);
    _logger.info('Processing ${result.length} formats for merge');
    final mergeFormats = result
        .where((e) =>
            e.containsKey('video') &&
            e.containsKey('audio')) // Check for video and audio keys
        .map((e) {
      final castedMap = e.cast<String, dynamic>();
      _logger.info('Casted map: $castedMap');
      return MergeFormat.fromMap(castedMap);
    }).toList();
    _logger.info('Returning ${mergeFormats.length} merge formats');
    return mergeFormats;
  }

  /// Fetches non-MP4 video with sound formats for conversion.
  static Future<List<CombinedFormat>>
      getNonMp4VideoWithSoundFormatsForConversion(String url) async {
    final result =
        await _fetchFormats('getNonMp4VideoWithSoundFormatsForConversion', url);
    return result
        .where((e) => e['type'] == 'combined' || e['needsConversion'] != null)
        .map((e) => CombinedFormat.fromMap(e))
        .toList();
  }

  /// Fetches all raw audio-only formats.
  static Future<List<Format>> getAllRawAudioOnlyFormats(String url) async {
    final result = await _fetchFormats('getAllRawAudioOnlyFormats', url);
    return result
        .where((e) => e['type'] != 'merge' && e['needsConversion'] == null)
        .map((e) => Format.fromMap(e))
        .toList();
  }

  /// Fetches non-MP3 audio-only formats for conversion.
  static Future<List<Format>> getNonMp3AudioOnlyFormatsForConversion(
      String url) async {
    final result =
        await _fetchFormats('getNonMp3AudioOnlyFormatsForConversion', url);
    return result
        .where((e) => e['type'] != 'merge' && e['needsConversion'] == null)
        .map((e) => Format.fromMap(e))
        .toList();
  }

  /// Fetches all video with sound formats (raw, merge, and convertible).
  static Future<List<dynamic>> getAllVideoWithSoundFormats(String url) async {
    final rawCombined = await getAllRawVideoWithSoundFormats(url);
    final mergeFormats = await getRawVideoAndAudioFormatsForMerge(url);
    final convertFormats =
        await getNonMp4VideoWithSoundFormatsForConversion(url);
    return [...rawCombined, ...mergeFormats, ...convertFormats];
  }

  /// Fetches all audio-only formats (raw and convertible).
  static Future<List<Format>> getAllAudioOnlyFormats(String url) async {
    final rawAudio = await getAllRawAudioOnlyFormats(url);
    final convertAudio = await getNonMp3AudioOnlyFormatsForConversion(url);
    return [...rawAudio, ...convertAudio];
  }

  /// Retrieves the thumbnail URL for a given video URL.
  static Future<String?> getThumbnailUrl(String url) async {
    try {
      _logger.info('Fetching thumbnail URL for: $url');
      final result =
          await _channel.invokeMethod('getThumbnailUrl', {'url': url});
      final thumbnailUrl = result as String?;
      _logger.info('Thumbnail URL fetched: $thumbnailUrl');
      return thumbnailUrl;
    } on PlatformException catch (e) {
      _logger.severe('Error fetching thumbnail URL: ${e.message}');
      return null;
    }
  }

  /// Starts a download task with the specified format and parameters.
  static Future<DownloadTask> download({
    required dynamic format,
    required String outputDir,
    required String url,
    required String originalName,
    bool overwrite = false,
  }) async {
    final outputPath = generateOutputPath(format, outputDir, originalName);
    final formatMap = convertFormatToMap(format);
    final taskId = await _startDownload(formatMap, outputPath, url, overwrite);
    return _createDownloadTask(taskId, outputPath);
  }

  /// Formats a byte size into a human-readable string (e.g., "734.01 KB").
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

  /// Internal method to fetch formats from the native side.
  static Future<List<Map<String, dynamic>>> _fetchFormats(
      String method, String url) async {
    try {
      _logger.info('Fetching $method for URL: $url');
      final result = await _channel.invokeMethod(method, {'url': url});
      final formats = (result as List<dynamic>)
          .map((e) => (e as Map<dynamic, dynamic>).cast<String, dynamic>())
          .toList();
      _logger.info('Fetched ${formats.length} formats');
      _logger.info('Raw format data: $formats');
      for (var i = 0; i < formats.length; i++) {
        final format = formats[i];
        if (format.containsKey('video') && format.containsKey('audio')) {
          final mergeFormat = MergeFormat.fromMap(format);
          _logger.info('Format[$i]: ${mergeFormat.toLogString(formatBytes)}');
        } else if (format['type'] == 'combined' ||
            format.containsKey('needsConversion')) {
          final combinedFormat = CombinedFormat.fromMap(format);
          _logger
              .info('Format[$i]: ${combinedFormat.toLogString(formatBytes)}');
        } else {
          final basicFormat = Format.fromMap(format);
          _logger.info('Format[$i]: ${basicFormat.toLogString(formatBytes)}');
        }
      }
      return formats;
    } on PlatformException catch (e) {
      _logger.severe('Error fetching $method: ${e.message}');
      rethrow;
    }
  }

  /// Internal method to start a download task.
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

  /// Internal method to create a download task with progress and state streams.
  static DownloadTask _createDownloadTask(String taskId, String outputPath) {
    final progressController = StreamController<DownloadProgress>.broadcast();
    final stateController = StreamController<DownloadState>.broadcast();

    late StreamSubscription subscription;
    subscription = _eventChannel.receiveBroadcastStream().listen((event) {
      final map = event as Map<dynamic, dynamic>;
      if (map['taskId'] != taskId) return;
      if (map['type'] == 'progress') {
        progressController
            .add(DownloadProgress.fromMap(map.cast<String, dynamic>()));
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
      outputPath: outputPath,
    );
  }
}
