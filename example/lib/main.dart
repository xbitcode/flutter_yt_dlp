// C:\Users\Abdullah\flutter_apps_temp\flutter_yt_dlp\example\lib\main.dart
import 'package:flutter/material.dart';
import 'package:flutter_yt_dlp/flutter_yt_dlp.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  FlutterYtDlpPlugin.initialize();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  String status = "Idle";
  double progress = 0.0;
  DownloadTask? currentTask;
  String? thumbnailUrl;

  Future<String> _getOutputDir() async {
    final directory = await getExternalStorageDirectory();
    return directory?.path ?? (throw Exception("Unable to access storage"));
  }

  Future<bool> _requestStoragePermission() async {
    return await Permission.storage.request().isGranted;
  }

  Future<void> _fetchThumbnail(String url) async {
    final urlResult = await FlutterYtDlpPlugin.getThumbnailUrl(url);
    setState(() => thumbnailUrl = urlResult);
  }

  Future<void> _startDownload<T>({
    required String url,
    required String originalName,
    required Future<List<T>> Function(String) fetchFormats,
    required String label,
  }) async {
    if (!await _requestStoragePermission()) {
      setState(() => status = "Permission denied");
      return;
    }

    final outputDir = await _getOutputDir();
    final formats = await fetchFormats(url);
    if (formats.isEmpty) {
      setState(() => status = "$label: No formats found");
      return;
    }

    final smallestFormat = _selectSmallestFormat(formats);
    setState(() => status = "$label: Starting download");

    final task = await FlutterYtDlpPlugin.download(
      format: smallestFormat,
      outputDir: outputDir,
      url: url,
      originalName: originalName,
      overwrite: true,
    );

    setState(() => currentTask = task);

    task.progressStream.listen((p) {
      setState(() {
        progress = p.percentage;
        status =
            "$label: ${FlutterYtDlpPlugin.formatBytes(p.downloadedBytes)} / ${FlutterYtDlpPlugin.formatBytes(p.totalBytes)}";
      });
    });

    task.stateStream.listen((s) {
      setState(() {
        status = "$label: ${s.name} - File: ${task.outputPath}";
        if (s == DownloadState.completed ||
            s == DownloadState.canceled ||
            s == DownloadState.failed) {
          progress = 0.0;
          currentTask = null;
        }
      });
    });
  }

  dynamic _selectSmallestFormat<T>(List<T> formats) {
    if (formats.first is MergeFormat) {
      final mergeFormats = formats.cast<MergeFormat>();
      final smallestVideo =
          _reduceFormats(mergeFormats.map((f) => f.video).toList());
      final smallestAudio =
          _reduceFormats(mergeFormats.map((f) => f.audio).toList());
      return MergeFormat(video: smallestVideo, audio: smallestAudio);
    }
    return _reduceFormats(formats.cast<Format>());
  }

  Format _reduceFormats(List<Format> formats) {
    return formats.reduce((a, b) => a.size > 0 && b.size > 0
        ? (a.size < b.size ? a : b)
        : (a.size > 0 ? a : b));
  }

  void _cancelDownload() {
    currentTask?.cancel();
    setState(() => status = "Download canceled");
  }

  @override
  void initState() {
    super.initState();
    _fetchThumbnail("https://youtu.be/l2Uoid2eqII?si=W9xgTB9bfRK5ss6V");
  }

  @override
  Widget build(BuildContext context) {
    const url = "https://youtu.be/l2Uoid2eqII?si=W9xgTB9bfRK5ss6V";
    const originalName = "RickRoll";

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('FlutterYtDlp Demo')),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (thumbnailUrl != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.network(
                      thumbnailUrl!,
                      height: 100,
                      width: 100,
                      errorBuilder: (context, error, stackTrace) =>
                          const Text("Failed to load thumbnail"),
                    ),
                  ),
                Text(status),
                const SizedBox(height: 20),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _startDownload<CombinedFormat>(
                    url: url,
                    originalName: originalName,
                    fetchFormats:
                        FlutterYtDlpPlugin.getAllRawVideoWithSoundFormats,
                    label: "Raw Video+Sound",
                  ),
                  child: const Text("Download Raw Video+Sound"),
                ),
                ElevatedButton(
                  onPressed: () => _startDownload<MergeFormat>(
                    url: url,
                    originalName: originalName,
                    fetchFormats:
                        FlutterYtDlpPlugin.getRawVideoAndAudioFormatsForMerge,
                    label: "Merge Video+Audio",
                  ),
                  child: const Text("Download Merge Video+Audio"),
                ),
                ElevatedButton(
                  onPressed: () => _startDownload<CombinedFormat>(
                    url: url,
                    originalName: originalName,
                    fetchFormats: FlutterYtDlpPlugin
                        .getNonMp4VideoWithSoundFormatsForConversion,
                    label: "Convert Video+Sound",
                  ),
                  child: const Text("Download Convert Video+Sound"),
                ),
                ElevatedButton(
                  onPressed: () => _startDownload<Format>(
                    url: url,
                    originalName: originalName,
                    fetchFormats: FlutterYtDlpPlugin.getAllRawAudioOnlyFormats,
                    label: "Raw Audio",
                  ),
                  child: const Text("Download Raw Audio"),
                ),
                ElevatedButton(
                  onPressed: () => _startDownload<Format>(
                    url: url,
                    originalName: originalName,
                    fetchFormats: FlutterYtDlpPlugin
                        .getNonMp3AudioOnlyFormatsForConversion,
                    label: "Convert Audio",
                  ),
                  child: const Text("Download Convert Audio"),
                ),
                ElevatedButton(
                  onPressed: currentTask != null ? _cancelDownload : null,
                  child: const Text("Cancel Download"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
