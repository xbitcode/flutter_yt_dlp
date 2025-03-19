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
    _initializeProvider();
  }

  void _initializeProvider() {
    final provider = Provider.of<DownloadProvider>(context, listen: false);
    _requestStoragePermission().then((_) => provider.initializeDownloadsDir());
    provider.listenToDownloadEvents();
  }

  Future<void> _requestStoragePermission() async {
    if (!await Permission.storage.request().isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission required')),
      );
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
      builder: (context, provider, _) => _buildScaffold(context, provider),
    );
  }

  Widget _buildScaffold(BuildContext context, DownloadProvider provider) {
    final formats = _getAllFormats(provider.videoInfo);
    return Scaffold(
      appBar: AppBar(title: const Text('Download Screen')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: _buildContent(provider, formats),
        ),
      ),
    );
  }

  Widget _buildContent(
      DownloadProvider provider, List<Map<String, dynamic>> formats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UrlInput(controller: _urlController, provider: provider),
        const SizedBox(height: 16),
        if (provider.videoInfo != null) ...[
          _buildVideoTitle(provider),
          const SizedBox(height: 8),
          _buildThumbnail(provider),
          const SizedBox(height: 16),
          FormatSelector(formats: formats, provider: provider),
          const SizedBox(height: 16),
          DownloadControls(provider: provider, url: _urlController.text),
          const SizedBox(height: 16),
          _buildProgressIndicator(provider),
          const SizedBox(height: 8),
          _buildStatusText(provider),
        ],
      ],
    );
  }

  Widget _buildVideoTitle(DownloadProvider provider) {
    return Text('Title: ${provider.videoInfo!['title']}');
  }

  Widget _buildThumbnail(DownloadProvider provider) {
    final thumbnailUrl = provider.videoInfo!['thumbnail'] as String?;
    return thumbnailUrl != null
        ? Image.network(
            thumbnailUrl,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Text('Failed to load thumbnail'),
          )
        : const SizedBox.shrink();
  }

  Widget _buildProgressIndicator(DownloadProvider provider) {
    return LinearProgressIndicator(value: provider.progress);
  }

  Widget _buildStatusText(DownloadProvider provider) {
    return Text('Status: ${provider.status}');
  }
}
