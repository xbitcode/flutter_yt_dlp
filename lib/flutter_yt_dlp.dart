// C:\Users\Abdullah\flutter_apps_temp\flutter_yt_dlp\lib\flutter_yt_dlp.dart
export 'models.dart';
export 'utils.dart';

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'models.dart';
import 'utils.dart';

class FlutterYtDlpPlugin {
  static const MethodChannel _channel = MethodChannel('flutter_yt_dlp');
  static const EventChannel _eventChannel =
      EventChannel('flutter_yt_dlp/events');
  static final Logger _logger = Logger('FlutterYtDlpPlugin');

  static void initialize() {
    try {
      setupLogging();
      print('FlutterYtDlpPlugin initialized');
    } catch (e) {
      print('Error in FlutterYtDlpPlugin initialization: $e');
    }
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

  /// Initiates a download task, letting the plugin determine the file name and extension.
  static Future<DownloadTask> download({
    required dynamic format,
    required String outputDir,
    required String url,
    bool overwrite = false,
  }) async {
    final formatMap = convertFormatToMap(format);
    final taskId = await _startDownload(formatMap, outputDir, url, overwrite);
    final outputPath =
        await _channel.invokeMethod('getOutputPath', {'taskId': taskId});
    return _createDownloadTask(taskId, outputPath as String);
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
      for (var f in formats) {
        _logger.info(f['type'] == 'merge'
            ? MergeFormat.fromMap(f).toLogString(formatBytes)
            : f['type'] == 'combined'
                ? CombinedFormat.fromMap(f).toLogString(formatBytes)
                : Format.fromMap(f).toLogString(formatBytes));
      }
      return formats;
    } on PlatformException catch (e) {
      _logger.severe('Error fetching $method: ${e.message}');
      rethrow;
    }
  }

  static Future<String> _startDownload(
    Map<String, dynamic> formatMap,
    String outputDir,
    String url,
    bool overwrite,
  ) async {
    try {
      _logger.info('Starting download for URL: $url to directory: $outputDir');
      return await _channel.invokeMethod('startDownload', {
        'format': formatMap,
        'outputDir': outputDir, // Changed from outputPath to outputDir
        'url': url,
        'overwrite': overwrite,
      }) as String;
    } on PlatformException catch (e) {
      _logger.severe('Error starting download: ${e.message}');
      rethrow;
    }
  }

  static DownloadTask _createDownloadTask(String taskId, String outputPath) {
    final progressController = StreamController<DownloadProgress>.broadcast();
    final stateController = StreamController<DownloadState>.broadcast();

    late StreamSubscription subscription;
    subscription = _eventChannel.receiveBroadcastStream().listen((event) {
      final map = event as Map<Object?, Object?>;
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
