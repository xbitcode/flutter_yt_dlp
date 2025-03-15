import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'logger.dart';
import 'models.dart';
import 'format_categorizer.dart';

class FlutterYtDlpClient {
  static const MethodChannel _channel = MethodChannel('flutter_yt_dlp');
  static const EventChannel _eventChannel =
      EventChannel('flutter_yt_dlp/events');
  static final FormatCategorizer _formatCategorizer = FormatCategorizer();

  FlutterYtDlpClient() {
    PluginLogger.setup();
    PluginLogger.info('FlutterYtDlpClient initialized');
  }

  Future<Map<String, dynamic>> getVideoInfo(String url) async {
    try {
      PluginLogger.info('Fetching video info for URL: $url');
      final info = await _channel.invokeMethod('getVideoInfo', {'url': url});
      final infoMap = _convertToMap(info);
      final categorized = _categorizeVideoInfo(infoMap);
      PluginLogger.info('Video info fetched successfully for $url');
      return categorized;
    } catch (e, stackTrace) {
      PluginLogger.error('Failed to fetch video info for $url', e, stackTrace);
      rethrow;
    }
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
  }) async {
    final args = {
      'format': format,
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
        final stateName = DownloadState.values[stateIndex].name;
        eventMap['stateName'] = stateName;
        PluginLogger.info(
            'Received state event: taskId=${eventMap['taskId']}, state=$stateName');
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
            value is Map ? _convertToMap(value) : value,
          ));
    }
    return {};
  }

  Map<String, dynamic> _categorizeVideoInfo(Map<String, dynamic> info) {
    final rawFormats = info['formats'] as List<dynamic>? ?? [];
    final formats = rawFormats.map(_convertToMap).toList();
    return {
      'title': info['title'] as String? ?? 'unknown',
      'thumbnail': info['thumbnail'] as String?,
      'rawVideoWithSoundFormats':
          _formatCategorizer.getRawVideoWithSoundFormats(formats),
      'mergeFormats': _formatCategorizer.getMergeFormats(formats),
      'rawAudioOnlyFormats': _formatCategorizer.getRawAudioOnlyFormats(formats),
    };
  }
}
