import 'package:flutter/material.dart';
import '../download_provider.dart';

class FormatSelector extends StatelessWidget {
  final DownloadProvider provider;
  final List<Map<String, dynamic>> formats;

  const FormatSelector(
      {required this.provider, required this.formats, super.key});

  String _formatDisplayName(Map<String, dynamic> format) {
    if (format['type'] == 'merge') {
      final video = format['video'] as Map<String, dynamic>;
      final audio = format['audio'] as Map<String, dynamic>;
      return 'Merge: ${video['resolution']} (${audio['bitrate']}kbps)';
    }
    return '${format['resolution']} (${format['bitrate']}kbps) - ${format['ext']}';
  }

  bool _canToggleConversion() {
    if (provider.selectedFormat == null) return false;
    final format = provider.selectedFormat!;
    if (format['type'] == 'merge')
      return false; // Merge formats are always mp4, no conversion toggle
    final ext = format['ext'] as String? ?? 'unknown';
    final isVideoWithSound =
        format['type'] == 'combined' && format['needsConversion'] != null;
    return (isVideoWithSound && ext != 'mp4') ||
        (!isVideoWithSound && ext != 'mp3');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Format:'),
        DropdownButton<Map<String, dynamic>>(
          value: provider.selectedFormat,
          isExpanded: true,
          items: formats.map((format) {
            return DropdownMenuItem(
              value: format,
              child: Text(_formatDisplayName(format)),
            );
          }).toList(),
          onChanged: provider.currentTask == null
              ? provider.updateSelectedFormat
              : null,
        ),
        if (_canToggleConversion())
          CheckboxListTile(
            title: const Text('Download as Raw (unconverted)'),
            value: provider.downloadAsRaw,
            onChanged: provider.currentTask == null
                ? provider.toggleDownloadAsRaw
                : null,
          ),
      ],
    );
  }
}
