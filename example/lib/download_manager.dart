import 'package:flutter_yt_dlp/flutter_yt_dlp.dart';

class DownloadManager {
  final FlutterYtDlpClient _client = FlutterYtDlpClient();

  /// Constructs the manager with a ready-to-use client.
  DownloadManager();

  /// Fetches video information for the given URL.
  Future<Map<String, dynamic>> fetchVideoInfo(String url) =>
      _client.getVideoInfo(url);

  /// Gets the thumbnail URL for the given video.
  Future<String> getThumbnailUrl(String url) => _client.getThumbnailUrl(url);

  /// Starts a download with the specified parameters.
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

  /// Cancels a download by task ID.
  Future<void> cancelDownload(String taskId) => _client.cancelDownload(taskId);

  /// Streams download events (progress, state changes).
  Stream<Map<String, dynamic>> getDownloadEvents() =>
      _client.getDownloadEvents();
}
