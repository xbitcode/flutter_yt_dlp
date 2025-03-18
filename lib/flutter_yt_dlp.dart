import 'dart:async';
import 'package:flutter/services.dart';
import 'logger.dart';
import 'format_categorizer.dart';
import 'utils.dart';

/// A client for interacting with the yt-dlp plugin to fetch video info and manage downloads.
class FlutterYtDlpClient {
  static const MethodChannel _channel = MethodChannel('flutter_yt_dlp');
  static const EventChannel _eventChannel =
      EventChannel('flutter_yt_dlp/events');
  final FormatCategorizer _categorizer = FormatCategorizer();

  /// Initializes the client and sets up logging.
  FlutterYtDlpClient() {
    PluginLogger.setup();
    PluginLogger.info('FlutterYtDlpClient initialized');
  }

  /// Fetches video information for the given URL, including formats and metadata.
  ///
  /// [url] The video URL to fetch info for.
  /// [forceRefresh] If true, bypasses cache and fetches fresh data. Defaults to false.
  /// Returns a map with video details or throws an exception on failure.
  Future<Map<String, dynamic>> getVideoInfo(String url,
      {bool forceRefresh = false}) async {
    try {
      PluginLogger.info('Fetching video info for $url');
      final info = await _channel.invokeMethod(
          'getVideoInfo', {'url': url, 'forceRefresh': forceRefresh});
      final typedInfo = convertPlatformMap(info);
      return _categorizeVideoInfo(typedInfo);
    } catch (e, stackTrace) {
      PluginLogger.error('Failed to fetch video info for $url', e, stackTrace);
      rethrow;
    }
  }

  /// Retrieves a list of combined video-with-sound formats for the given URL.
  ///
  /// [url] The video URL to fetch formats for.
  /// Returns a list of format maps or throws an exception on failure.
  Future<List<Map<String, dynamic>>> getCombinedFormats(String url) async {
    final info = await getVideoInfo(url);
    return info['rawVideoWithSoundFormats'] as List<Map<String, dynamic>>;
  }

  /// Retrieves a list of merge formats (separate video and audio) for the given URL.
  ///
  /// [url] The video URL to fetch formats for.
  /// Returns a list of format maps or throws an exception on failure.
  Future<List<Map<String, dynamic>>> getMergeFormats(String url) async {
    final info = await getVideoInfo(url);
    return info['mergeFormats'] as List<Map<String, dynamic>>;
  }

  /// Retrieves a list of audio-only formats for the given URL.
  ///
  /// [url] The video URL to fetch formats for.
  /// Returns a list of format maps or throws an exception on failure.
  Future<List<Map<String, dynamic>>> getAudioOnlyFormats(String url) async {
    final info = await getVideoInfo(url);
    return info['rawAudioOnlyFormats'] as List<Map<String, dynamic>>;
  }

  /// Fetches the thumbnail URL for the given video URL.
  ///
  /// [url] The video URL to fetch the thumbnail for.
  /// Returns the thumbnail URL as a string or throws an exception on failure.
  Future<String> getThumbnailUrl(String url) async {
    try {
      PluginLogger.info('Fetching thumbnail for $url');
      return await _channel.invokeMethod('getThumbnailUrl', {'url': url})
          as String;
    } catch (e, stackTrace) {
      PluginLogger.error('Failed to fetch thumbnail for $url', e, stackTrace);
      rethrow;
    }
  }

  /// Starts a download for the specified video format and URL.
  ///
  /// [format] The format details for the download.
  /// [outputDir] The directory to save the downloaded file.
  /// [url] The video URL to download.
  /// [overwrite] Whether to overwrite existing files. Defaults to false.
  /// [overrideName] Optional custom filename to use instead of the video title.
  /// Returns the task ID of the download or throws an exception on failure.
  Future<String> startDownload({
    required Map<String, dynamic> format,
    required String outputDir,
    required String url,
    bool overwrite = false,
    String? overrideName,
  }) async {
    final args = {
      'format': Map<String, dynamic>.from(format),
      'outputDir': outputDir,
      'url': url,
      'overwrite': overwrite,
      'overrideName': overrideName,
    };
    try {
      PluginLogger.info('Starting download for $url');
      return await _channel.invokeMethod('startDownload', args) as String;
    } catch (e, stackTrace) {
      PluginLogger.error('Failed to start download for $url', e, stackTrace);
      rethrow;
    }
  }

  /// Cancels a download in progress using the given task ID.
  ///
  /// [taskId] The ID of the download task to cancel.
  /// Throws an exception if cancellation fails.
  Future<void> cancelDownload(String taskId) async {
    try {
      PluginLogger.info('Cancelling download $taskId');
      await _channel.invokeMethod('cancelDownload', {'taskId': taskId});
    } catch (e, stackTrace) {
      PluginLogger.error('Failed to cancel download $taskId', e, stackTrace);
      rethrow;
    }
  }

  /// Provides a stream of download events (progress, state changes).
  ///
  /// Returns a stream of event maps with download status updates.
  Stream<Map<String, dynamic>> getDownloadEvents() {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => convertPlatformMap(event));
  }

  /// Categorizes video formats into combined, merge, and audio-only types.
  ///
  /// [info] The raw video info map containing format data.
  /// Returns a map with categorized format lists.
  Map<String, dynamic> _categorizeVideoInfo(Map<String, dynamic> info) {
    final formatMaps = (info['formats'] as List).cast<Map<String, dynamic>>();
    return {
      'title': info['title'] as String? ?? 'unknown',
      'thumbnail': info['thumbnail'] as String?,
      'formats': formatMaps,
      'rawVideoWithSoundFormats':
          _categorizer.getFormatsByType(formatMaps, FormatTypes.videoWithSound),
      'mergeFormats':
          _categorizer.getFormatsByType(formatMaps, FormatTypes.merge),
      'rawAudioOnlyFormats':
          _categorizer.getFormatsByType(formatMaps, FormatTypes.audioOnly),
    };
  }
}
