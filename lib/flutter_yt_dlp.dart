import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'models.dart';
import 'utils.dart';

/// Main plugin class for interacting with yt-dlp and FFmpeg.
///
/// Provides methods to fetch media formats and initiate downloads with progress
/// and state tracking.
class FlutterYtDlpPlugin {
  static const MethodChannel _channel = MethodChannel('flutter_yt_dlp');
  static const EventChannel _eventChannel =
      EventChannel('flutter_yt_dlp/events');
  static final Logger _logger = Logger('FlutterYtDlpPlugin');

  /// Initializes the plugin with logging setup.
  static void initialize() {
    try {
      setupLogging();
      print('FlutterYtDlpPlugin initialized');
    } catch (e) {
      print('Error in FlutterYtDlpPlugin initialization: $e');
    }
  }

  /// Fetches all raw video formats with sound for a given URL.
  static Future<List<CombinedFormat>> getAllRawVideoWithSoundFormats(
      String url) async {
    final result = await _fetchFormats('getAllRawVideoWithSoundFormats', url);
    return result.map((e) => CombinedFormat.fromMap(e)).toList();
  }

  /// Fetches raw video and audio formats suitable for merging.
  static Future<List<MergeFormat>> getRawVideoAndAudioFormatsForMerge(
      String url) async {
    final result =
        await _fetchFormats('getRawVideoAndAudioFormatsForMerge', url);
    return result.map((e) => MergeFormat.fromMap(e)).toList();
  }

  /// Fetches non-MP4 video formats with sound for conversion to MP4.
  static Future<List<CombinedFormat>>
      getNonMp4VideoWithSoundFormatsForConversion(String url) async {
    final result =
        await _fetchFormats('getNonMp4VideoWithSoundFormatsForConversion', url);
    return result.map((e) => CombinedFormat.fromMap(e)).toList();
  }

  /// Fetches all raw audio-only formats for a given URL.
  static Future<List<Format>> getAllRawAudioOnlyFormats(String url) async {
    final result = await _fetchFormats('getAllRawAudioOnlyFormats', url);
    return result.map((e) => Format.fromMap(e)).toList();
  }

  /// Fetches non-MP3 audio-only formats for conversion to MP3.
  static Future<List<Format>> getNonMp3AudioOnlyFormatsForConversion(
      String url) async {
    final result =
        await _fetchFormats('getNonMp3AudioOnlyFormatsForConversion', url);
    return result.map((e) => Format.fromMap(e)).toList();
  }

  /// Fetches all available video with sound formats (raw, merge, and conversion).
  static Future<List<dynamic>> getAllVideoWithSoundFormats(String url) async {
    final rawCombined = await getAllRawVideoWithSoundFormats(url);
    final mergeFormats = await getRawVideoAndAudioFormatsForMerge(url);
    final convertFormats =
        await getNonMp4VideoWithSoundFormatsForConversion(url);
    return [...rawCombined, ...mergeFormats, ...convertFormats];
  }

  /// Fetches all available audio-only formats (raw and conversion).
  static Future<List<Format>> getAllAudioOnlyFormats(String url) async {
    final rawAudio = await getAllRawAudioOnlyFormats(url);
    final convertAudio = await getNonMp3AudioOnlyFormatsForConversion(url);
    return [...rawAudio, ...convertAudio];
  }

  /// Initiates a download task for a specified format.
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
    return _createDownloadTask(taskId);
  }

  /// Formats a byte count into a human-readable string (e.g., '1.23 MB').
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
    );
  }
}
