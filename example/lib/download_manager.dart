import 'package:flutter_yt_dlp/flutter_yt_dlp.dart';

class DownloadManager {
  final FlutterYtDlpClient _client = FlutterYtDlpClient();

  DownloadManager() {
    _initializeClient();
  }

  Future<void> _initializeClient() async {
    await _client.initialize();
  }

  Future<Map<String, dynamic>> fetchVideoInfo(String url) =>
      _client.getVideoInfo(url);
  Future<String> getThumbnailUrl(String url) => _client.getThumbnailUrl(url);
  Future<String> startDownload(
    Map<String, dynamic> format,
    String outputDir,
    String url,
    bool overwrite, {
    String? overrideName,
  }) =>
      _client.startDownload(
        format: format,
        outputDir: outputDir,
        url: url,
        overwrite: overwrite,
        overrideName: overrideName,
      );
  Future<void> cancelDownload(String taskId) => _client.cancelDownload(taskId);
  Stream<Map<String, dynamic>> getDownloadEvents() =>
      _client.getDownloadEvents();
}
