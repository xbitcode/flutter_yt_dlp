import 'dart:async';
import 'package:flutter_yt_dlp/flutter_yt_dlp.dart';

class DownloadManager {
  final FlutterYtDlpClient _client;

  DownloadManager() : _client = FlutterYtDlpClient();

  Future<Map<String, dynamic>> fetchVideoInfo(String url) async {
    return await _client.getVideoInfo(url);
  }

  Future<String> getThumbnailUrl(String url) async {
    return await _client.getThumbnailUrl(url);
  }

  Future<String> startDownload(
    Map<String, dynamic> format,
    String outputDir,
    String url,
    bool overwrite, {
    String? overrideName,
  }) async {
    return await _client.startDownload(
      format: format,
      outputDir: outputDir,
      url: url,
      overwrite: overwrite,
      overrideName: overrideName,
    );
  }

  Future<void> cancelDownload(String taskId) async {
    await _client.cancelDownload(taskId);
  }

  Stream<Map<String, dynamic>> getDownloadEvents() {
    return _client.getDownloadEvents();
  }
}
