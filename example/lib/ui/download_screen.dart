import 'package:flutter/material.dart';
import '../download_manager.dart';
import 'package:flutter_yt_dlp/flutter_yt_dlp.dart';

class DownloadScreen extends StatefulWidget {
  final DownloadManager downloadManager;

  const DownloadScreen({super.key, required this.downloadManager});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  static const _url = "https://youtu.be/l2Uoid2eqII?si=W9xgTB9bfRK5ss6V";
  static const _originalName = "RickRoll";

  void _updateStatus(String newStatus) =>
      setState(() => widget.downloadManager.status = newStatus);
  void _updateProgress(double newProgress) =>
      setState(() => widget.downloadManager.progress = newProgress);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FlutterYtDlp Demo')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildThumbnail(),
              Text(widget.downloadManager.status),
              const SizedBox(height: 20),
              LinearProgressIndicator(value: widget.downloadManager.progress),
              const SizedBox(height: 20),
              _buildDownloadButton("Raw Video+Sound",
                  FlutterYtDlpPlugin.getAllRawVideoWithSoundFormats),
              _buildDownloadButton("Merge Video+Audio",
                  FlutterYtDlpPlugin.getRawVideoAndAudioFormatsForMerge),
              _buildDownloadButton(
                  "Convert Video+Sound",
                  FlutterYtDlpPlugin
                      .getNonMp4VideoWithSoundFormatsForConversion),
              _buildDownloadButton(
                  "Raw Audio", FlutterYtDlpPlugin.getAllRawAudioOnlyFormats),
              _buildDownloadButton("Convert Audio",
                  FlutterYtDlpPlugin.getNonMp3AudioOnlyFormatsForConversion),
              _buildDownloadButton("All Video+Sound",
                  FlutterYtDlpPlugin.getAllVideoWithSoundFormats),
              _buildDownloadButton(
                  "All Audio", FlutterYtDlpPlugin.getAllAudioOnlyFormats),
              _buildCancelButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return widget.downloadManager.thumbnailUrl != null
        ? Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.network(
              widget.downloadManager.thumbnailUrl!,
              height: 100,
              width: 100,
              errorBuilder: (context, error, stackTrace) =>
                  const Text("Failed to load thumbnail"),
            ),
          )
        : const SizedBox.shrink();
  }

  Widget _buildDownloadButton<T>(
      String label, Future<List<T>> Function(String) fetchFormats) {
    return ElevatedButton(
      onPressed: () => widget.downloadManager.startDownload<T>(
        url: _url,
        originalName: _originalName,
        fetchFormats: fetchFormats,
        label: label,
        onStatusUpdate: _updateStatus,
        onProgressUpdate: _updateProgress,
      ),
      child: Text("Download $label"),
    );
  }

  Widget _buildCancelButton() {
    return ElevatedButton(
      onPressed: widget.downloadManager.currentTask != null
          ? () => widget.downloadManager.cancelDownload(_updateStatus)
          : null,
      child: const Text("Cancel Download"),
    );
  }
}
