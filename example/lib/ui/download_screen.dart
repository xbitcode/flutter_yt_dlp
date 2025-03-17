import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../download_provider.dart';
import 'url_input.dart';
import 'format_selector.dart';
import 'download_controls.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final _urlController =
      TextEditingController(text: 'https://youtu.be/nl8o9PsJPAQ');

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<DownloadProvider>(context, listen: false);
    _requestStoragePermission().then((_) => provider.initializeDownloadsDir());
    provider.listenToDownloadEvents();
  }

  Future<void> _requestStoragePermission() async {
    if (!await Permission.storage.request().isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission required')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getAllFormats(Map<String, dynamic>? info) {
    return [
      ...(info?['rawVideoWithSoundFormats'] as List<dynamic>? ?? []),
      ...(info?['mergeFormats'] as List<dynamic>? ?? []),
      ...(info?['rawAudioOnlyFormats'] as List<dynamic>? ?? []),
    ].cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadProvider>(
      builder: (context, provider, _) {
        final formats = _getAllFormats(provider.videoInfo);
        return Scaffold(
          appBar: AppBar(title: const Text('Download Screen')),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UrlInput(controller: _urlController, provider: provider),
                  const SizedBox(height: 16),
                  if (provider.videoInfo != null) ...[
                    Text('Title: ${provider.videoInfo!['title']}'),
                    const SizedBox(height: 8),
                    if (provider.videoInfo!['thumbnail'] != null)
                      Image.network(provider.videoInfo!['thumbnail'],
                          height: 150, fit: BoxFit.cover),
                  ],
                  const SizedBox(height: 16),
                  Text('Status: ${provider.status}'),
                  LinearProgressIndicator(value: provider.progress),
                  const SizedBox(height: 16),
                  if (formats.isNotEmpty)
                    FormatSelector(provider: provider, formats: formats),
                  const SizedBox(height: 16),
                  DownloadControls(
                      provider: provider, url: _urlController.text),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
