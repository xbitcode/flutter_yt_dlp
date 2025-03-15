import 'package:flutter/material.dart';
import '../download_provider.dart';

class UrlInput extends StatelessWidget {
  final TextEditingController controller;
  final DownloadProvider provider;

  const UrlInput({required this.controller, required this.provider, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Enter Video URL',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: provider.currentTask == null
              ? () => provider.fetchVideoInfo(controller.text)
              : null,
          child: const Text('Fetch Video Info'),
        ),
      ],
    );
  }
}
