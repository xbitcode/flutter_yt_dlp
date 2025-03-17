import 'dart:async';
import 'package:flutter/services.dart';
import 'logger.dart';
import 'models.dart';
import 'format_categorizer.dart' as categorizer;

class FlutterYtDlpClient {
  static const MethodChannel _channel = MethodChannel('flutter_yt_dlp');
  static const EventChannel _eventChannel =
      EventChannel('flutter_yt_dlp/events');
  static final categorizer.FormatCategorizer _categorizer =
      categorizer.FormatCategorizer();

  /// Initializes the client and sets up logging.
  FlutterYtDlpClient() {
    PluginLogger.setup();
    PluginLogger.info('FlutterYtDlpClient initialized');
  }

  /// Fetches video metadata and categorizes formats.
  Future<Map<String, dynamic>> getVideoInfo(String url,
      {bool forceRefresh = false}) async {
    try {
      PluginLogger.info(
          'Fetching video info for URL: $url, forceRefresh: $forceRefresh');
      final info = await _channel.invokeMethod(
          'getVideoInfo', {'url': url, 'forceRefresh': forceRefresh});
      final convertedInfo = _convertToMap(info);
      final categorized = _categorizeVideoInfo(convertedInfo);
      PluginLogger.info('Video info fetched successfully for $url');
      return categorized;
    } catch (e, stackTrace) {
      PluginLogger.error('Failed to fetch video info for $url', e, stackTrace);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getFormats(
      String url, String formatType) async {
    final info = await getVideoInfo(url);
    return _categorizer.getFormatsByType(
        info['formats'] as List<Map<String, dynamic>>, formatType);
  }

  Future<String> getThumbnailUrl(String url) async {
    try {
      PluginLogger.info('Fetching thumbnail URL for: $url');
      final thumbnail = await _channel
          .invokeMethod('getThumbnailUrl', {'url': url}) as String;
      PluginLogger.info('Thumbnail URL fetched: $thumbnail');
      return thumbnail;
    } catch (e, stackTrace) {
      PluginLogger.error(
          'Failed to fetch thumbnail URL for $url', e, stackTrace);
      rethrow;
    }
  }

  Future<String> startDownload({
    required Map<String, dynamic> format,
    required String outputDir,
    required String url,
    bool overwrite = false,
    String? overrideName,
    bool convertToMp4 = false,
    bool convertToMp3 = false,
  }) async {
    final args = {
      'format': {
        ...format,
        'convertToMp4': convertToMp4,
        'convertToMp3': convertToMp3,
      },
      'outputDir': outputDir,
      'url': url,
      'overwrite': overwrite,
      'overrideName': overrideName,
    };
    try {
      PluginLogger.info('Starting download for URL: $url with format: $format');
      final taskId =
          await _channel.invokeMethod('startDownload', args) as String;
      PluginLogger.info('Download started with taskId: $taskId');
      return taskId;
    } catch (e, stackTrace) {
      PluginLogger.error('Failed to start download for $url', e, stackTrace);
      rethrow;
    }
  }

  Future<void> cancelDownload(String taskId) async {
    try {
      PluginLogger.info('Cancelling download with taskId: $taskId');
      await _channel.invokeMethod('cancelDownload', {'taskId': taskId});
      PluginLogger.info('Download cancelled: $taskId');
    } catch (e, stackTrace) {
      PluginLogger.error('Failed to cancel download $taskId', e, stackTrace);
      rethrow;
    }
  }

  Stream<Map<String, dynamic>> getDownloadEvents() {
    PluginLogger.info('Subscribing to download events');
    return _eventChannel.receiveBroadcastStream().map((event) {
      final eventMap = _convertToMap(event);
      if (eventMap['type'] == 'state') {
        final stateIndex = eventMap['state'] as int? ?? 0;
        eventMap['stateName'] = DownloadState.values[stateIndex].name;
        PluginLogger.info(
            'Received state event: taskId=${eventMap['taskId']}, state=${eventMap['stateName']}');
      } else {
        PluginLogger.info('Received event: $eventMap');
      }
      return eventMap;
    }).handleError((e, stackTrace) {
      PluginLogger.error('Error in download events stream', e, stackTrace);
    });
  }

  Map<String, dynamic> _convertToMap(dynamic data) {
    if (data is Map) {
      return data.map((key, value) => MapEntry(
            key.toString(),
            value is Map
                ? _convertToMap(value)
                : (value is List ? value.map(_convertToMap).toList() : value),
          ));
    } else if (data is List) {
      return {'items': data.map(_convertToMap).toList()};
    }
    PluginLogger.warning('Unexpected data type in _convertToMap: $data');
    return {};
  }

  Map<String, dynamic> _categorizeVideoInfo(Map<String, dynamic> info) {
    List<Map<String, dynamic>> formatMaps;

    if (info['formats'] is List) {
      formatMaps =
          (info['formats'] as List).map((f) => _convertToMap(f)).toList();
    } else if (info['formats'] is Map &&
        (info['formats'] as Map).containsKey('items')) {
      formatMaps = (info['formats']['items'] as List)
          .map((f) => _convertToMap(f))
          .toList();
    } else {
      PluginLogger.warning(
          'Formats field is not in expected format: ${info['formats']}');
      formatMaps = [];
    }

    PluginLogger.info('Raw formats: $formatMaps');

    final videoWithSound = _categorizer.getFormatsByType(
        formatMaps, categorizer.FormatTypes.videoWithSound);
    final mergeFormats = _categorizer.getFormatsByType(
        formatMaps, categorizer.FormatTypes.merge);
    final audioOnly = _categorizer.getFormatsByType(
        formatMaps, categorizer.FormatTypes.audioOnly);

    PluginLogger.info(
        'Categorized formats - VideoWithSound: ${videoWithSound.length}, Merge: ${mergeFormats.length}, AudioOnly: ${audioOnly.length}');
    PluginLogger.info(
        'Sample VideoWithSound: ${videoWithSound.isNotEmpty ? videoWithSound[0] : 'None'}');
    PluginLogger.info(
        'Sample Merge: ${mergeFormats.isNotEmpty ? mergeFormats[0] : 'None'}');

    return {
      'title': info['title'] as String? ?? 'unknown',
      'thumbnail': info['thumbnail'] as String?,
      'formats': formatMaps,
      'rawVideoWithSoundFormats': videoWithSound,
      'mergeFormats': mergeFormats,
      'rawAudioOnlyFormats': audioOnly,
    };
  }
}
