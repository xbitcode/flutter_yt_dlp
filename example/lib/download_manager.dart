import 'package:flutter/material.dart';
import 'package:flutter_yt_dlp/flutter_yt_dlp.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

/// Manages downloading media files using the FlutterYtDlpPlugin.
class DownloadManager {
  /// Current status of the download (e.g., "Idle", "Downloading").
  String status = "Idle";

  /// Progress of the download as a percentage (0.0 to 1.0).
  double progress = 0.0;

  /// The current download task, if any.
  DownloadTask? currentTask;

  /// URL of the thumbnail for the media being downloaded.
  String? thumbnailUrl;

  /// Gets the output directory for storing downloaded files.
  Future<String> _getOutputDir() async {
    final directory = await getExternalStorageDirectory();
    return directory?.path ?? (throw Exception("Unable to access storage"));
  }

  /// Requests storage permission from the user.
  Future<bool> _requestStoragePermission() async {
    return await Permission.storage.request().isGranted;
  }

  /// Fetches the thumbnail URL for a given video URL.
  Future<void> fetchThumbnail(String url) async {
    final urlResult = await FlutterYtDlpPlugin.getThumbnailUrl(url);
    thumbnailUrl = urlResult;
  }

  /// Starts a download with the specified parameters.
  Future<void> startDownload<T>({
    required String url,
    required String originalName,
    required Future<List<T>> Function(String) fetchFormats,
    required String label,
    required ValueChanged<String> onStatusUpdate,
    required ValueChanged<double> onProgressUpdate,
  }) async {
    if (!await _requestStoragePermission()) {
      onStatusUpdate("Permission denied");
      return;
    }

    final outputDir = await _getOutputDir();
    final formats = await fetchFormats(url);
    if (formats.isEmpty) {
      onStatusUpdate("$label: No formats found");
      return;
    }

    logFetchedFormats(formats, label); // Log formats here
    final smallestFormat = _selectSmallestFormat<T>(formats);
    onStatusUpdate("$label: Starting download");

    final task = await FlutterYtDlpPlugin.download(
      format: smallestFormat,
      outputDir: outputDir,
      url: url,
      originalName: originalName,
      overwrite: true,
    );

    currentTask = task;

    task.progressStream.listen((p) {
      onProgressUpdate(p.percentage);
      onStatusUpdate(
          "$label: ${FlutterYtDlpPlugin.formatBytes(p.downloadedBytes)} / ${FlutterYtDlpPlugin.formatBytes(p.totalBytes)}");
    });

    task.stateStream.listen((s) {
      onStatusUpdate("$label: ${s.name} - File: ${task.outputPath}");
      if (s == DownloadState.completed ||
          s == DownloadState.canceled ||
          s == DownloadState.failed) {
        onProgressUpdate(0.0);
        currentTask = null;
      }
    });
  }

  /// Logs the fetched formats for debugging purposes.
  void logFetchedFormats<T>(List<T> formats, String label) {
    debugPrint("Fetched ${formats.length} formats for $label:");
    for (var i = 0; i < formats.length; i++) {
      final format = formats[i];
      if (format is MergeFormat) {
        debugPrint(
            "Format[$i]: ${format.toLogString(FlutterYtDlpPlugin.formatBytes)}");
      } else if (format is CombinedFormat) {
        debugPrint(
            "Format[$i]: ${format.toLogString(FlutterYtDlpPlugin.formatBytes)}");
      } else if (format is Format) {
        debugPrint(
            "Format[$i]: ${format.toLogString(FlutterYtDlpPlugin.formatBytes)}");
      }
    }
  }

  /// Selects the smallest format from a list based on size.
  T _selectSmallestFormat<T>(List<T> formats) {
    if (formats.isEmpty) throw ArgumentError("Format list cannot be empty");

    final firstFormat = formats.first;
    if (firstFormat is MergeFormat) {
      final mergeFormats = formats.whereType<MergeFormat>().toList();
      return _reduceMergeFormats(mergeFormats) as T;
    } else if (firstFormat is CombinedFormat) {
      final combinedFormats = formats.whereType<CombinedFormat>().toList();
      return _reduceCombinedFormats(combinedFormats) as T;
    } else if (firstFormat is Format) {
      final basicFormats = formats.whereType<Format>().toList();
      return _reduceFormats(basicFormats) as T;
    } else {
      throw ArgumentError(
          "Unsupported format type: ${firstFormat.runtimeType}");
    }
  }

  /// Reduces a list of [MergeFormat] to the one with the smallest total size.
  MergeFormat _reduceMergeFormats(List<MergeFormat> formats) {
    return formats
        .reduce((a, b) => _getTotalSize(a) < _getTotalSize(b) ? a : b);
  }

  /// Reduces a list of [CombinedFormat] to the one with the smallest size.
  CombinedFormat _reduceCombinedFormats(List<CombinedFormat> formats) {
    return formats.reduce((a, b) => (a.size ?? 0) < (b.size ?? 0) ? a : b);
  }

  /// Reduces a list of [Format] to the one with the smallest size.
  Format _reduceFormats(List<Format> formats) {
    return formats.reduce((a, b) => (a.size ?? 0) < (b.size ?? 0) ? a : b);
  }

  /// Calculates the total size of a [MergeFormat] (video + audio).
  int _getTotalSize(MergeFormat format) =>
      (format.video.size ?? 0) + (format.audio.size ?? 0);

  /// Cancels the current download task.
  void cancelDownload(ValueChanged<String> onStatusUpdate) {
    currentTask?.cancel();
    onStatusUpdate("Download canceled");
  }
}
