import 'package:flutter/material.dart';
import '../download_provider.dart';

class DownloadControls extends StatelessWidget {
  final DownloadProvider provider;
  final String url;

  const DownloadControls(
      {required this.provider, required this.url, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed:
              provider.currentTask == null && provider.selectedFormat != null
                  ? () => provider.startDownload(url)
                  : null,
          child: const Text('Start Download'),
        ),
        ElevatedButton(
          onPressed:
              provider.currentTask != null ? provider.cancelDownload : null,
          child: const Text('Cancel Download'),
        ),
      ],
    );
  }
}
