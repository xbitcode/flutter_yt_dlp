import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../download_provider.dart';
import 'url_input.dart';
import 'format_selector.dart';
import 'download_controls.dart';

/// Displays the main screen for managing downloads.
class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final TextEditingController _urlController = TextEditingController(
      text: 'https://youtu.be/nl8o9PsJPAQ?si=IDsVPZ-3K3q2U6cg');

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<DownloadProvider>(context, listen: false);
    _requestStoragePermission().then((_) => provider.initializeDownloadsDir());
    provider.listenToDownloadEvents();
  }

  Future<void> _requestStoragePermission() async {
    if (!await Permission.storage.request().isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission denied')),
      );
    }
  }

  List<Map<String, dynamic>> _getAllFormats(Map<String, dynamic>? videoInfo) {
    if (videoInfo == null) return [];
    return [
      ...(videoInfo['rawVideoWithSoundFormats'] as List<dynamic>? ?? []),
      ...(videoInfo['mergeFormats'] as List<dynamic>? ?? []),
      ...(videoInfo['rawAudioOnlyFormats'] as List<dynamic>? ?? []),
    ].cast<Map<String, dynamic>>();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadProvider>(
      builder: (context, provider, child) {
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
                    Text(
                      'Title: ${provider.videoInfo?['title'] ?? 'Loading...'}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    if (provider.videoInfo?['thumbnail'] != null)
                      Image.network(
                        provider.videoInfo!['thumbnail'],
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.error),
                      ),
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
