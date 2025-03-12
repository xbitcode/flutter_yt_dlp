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
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String status = "Idle";
  double progress = 0.0;

  Future<String> _getOutputDir() async {
    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      throw Exception("Unable to access external storage directory");
    }
    return directory.path;
  }

  Future<bool> _requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<void> _downloadSmallestFormat<T>({
    required String url,
    required String originalName,
    required Future<List<T>> Function(String) fetchFormats,
    required String buttonLabel,
  }) async {
    try {
      if (!await _requestStoragePermission()) {
        setState(() => status = "Storage permission denied");
        return;
      }

      final outputDir = await _getOutputDir();
      final formats = await fetchFormats(url);
      if (formats.isEmpty) {
        setState(() => status = "No formats found for $buttonLabel");
        return;
      }

      dynamic smallestFormat;
      if (formats.first is MergeFormat) {
        final mergeFormats = formats.cast<MergeFormat>();
        final videoFormats = mergeFormats.map((f) => f.video).toSet().toList();
        final audioFormats = mergeFormats.map((f) => f.audio).toSet().toList();

        final smallestVideo = videoFormats.reduce((a, b) {
          if (a.size > 0 && b.size > 0) return a.size < b.size ? a : b;
          if (a.size > 0) return a;
          if (b.size > 0) return b;
          final resA = _parseResolution(a.resolution);
          final resB = _parseResolution(b.resolution);
          return resA != resB
              ? (resA < resB ? a : b)
              : (a.bitrate < b.bitrate ? a : b);
        });

        final smallestAudio = audioFormats.reduce((a, b) {
          if (a.size > 0 && b.size > 0) return a.size < b.size ? a : b;
          if (a.size > 0) return a;
          if (b.size > 0) return b;
          return a.bitrate < b.bitrate ? a : b;
        });

        smallestFormat =
            MergeFormat(video: smallestVideo, audio: smallestAudio);
      } else {
        smallestFormat = formats.reduce((a, b) {
          if (a is Format && b is Format) {
            if (a.size > 0 && b.size > 0) return a.size < b.size ? a : b;
            if (a.size > 0) return a;
            if (b.size > 0) return b;
            final resA = _parseResolution(a.resolution);
            final resB = _parseResolution(b.resolution);
            return resA != resB
                ? (resA < resB ? a : b)
                : (a.bitrate < b.bitrate ? a : b);
          }
          throw ArgumentError('Inconsistent format types in list');
        });
      }

      final task = await FlutterYtDlpPlugin.download(
        format: smallestFormat,
        outputDir: outputDir,
        url: url,
        originalName: originalName,
        overwrite: true,
      );

      task.progressStream.listen((p) {
        setState(() {
          progress = p.downloadedBytes / p.totalBytes;
          status =
              "$buttonLabel: ${FlutterYtDlpPlugin.formatBytes(p.downloadedBytes)} / ${FlutterYtDlpPlugin.formatBytes(p.totalBytes)}";
        });
      });

      task.stateStream.listen((s) {
        setState(() {
          status = "$buttonLabel: ${s.toString().split('.').last}";
          if (s == DownloadState.failed) {
            status += " - Download failed";
          } else if (s == DownloadState.canceled) {
            progress = 0.0;
          }
        });
      });
    } catch (e) {
      setState(() => status = "$buttonLabel: Error - $e");
    }
  }

  int _parseResolution(String resolution) {
    if (resolution == 'audio only') return 0;
    final parts = resolution.split('x');
    if (parts.length != 2) return 0;
    final width = int.tryParse(parts[0]) ?? 0;
    final height = int.tryParse(parts[1]) ?? 0;
    return width * height;
  }

  @override
  Widget build(BuildContext context) {
    const url = "https://www.youtube.com/watch?v=dQw4w9WgXcQ";
    const originalName = "RickRoll";

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('FlutterYtDlp Plugin Test')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(status),
              const SizedBox(height: 20),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _downloadSmallestFormat<CombinedFormat>(
                  url: url,
                  originalName: originalName,
                  fetchFormats:
                      FlutterYtDlpPlugin.getAllRawVideoWithSoundFormats,
                  buttonLabel: "Raw Video+Sound",
                ),
                child: const Text("Download Smallest Raw Video+Sound"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _downloadSmallestFormat<MergeFormat>(
                  url: url,
                  originalName: originalName,
                  fetchFormats:
                      FlutterYtDlpPlugin.getRawVideoAndAudioFormatsForMerge,
                  buttonLabel: "Merge Video+Audio",
                ),
                child: const Text("Download Smallest Merge Video+Audio"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _downloadSmallestFormat<CombinedFormat>(
                  url: url,
                  originalName: originalName,
                  fetchFormats: FlutterYtDlpPlugin
                      .getNonMp4VideoWithSoundFormatsForConversion,
                  buttonLabel: "Convert Video+Sound",
                ),
                child: const Text("Download Smallest Convert Video+Sound"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _downloadSmallestFormat<Format>(
                  url: url,
                  originalName: originalName,
                  fetchFormats: FlutterYtDlpPlugin.getAllRawAudioOnlyFormats,
                  buttonLabel: "Raw Audio",
                ),
                child: const Text("Download Smallest Raw Audio"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _downloadSmallestFormat<Format>(
                  url: url,
                  originalName: originalName,
                  fetchFormats:
                      FlutterYtDlpPlugin.getNonMp3AudioOnlyFormatsForConversion,
                  buttonLabel: "Convert Audio",
                ),
                child: const Text("Download Smallest Convert Audio"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
