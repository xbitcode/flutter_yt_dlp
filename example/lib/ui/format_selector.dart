import 'package:flutter/material.dart';
import '../download_provider.dart';

class FormatSelector extends StatelessWidget {
  final DownloadProvider provider;
  final List<Map<String, dynamic>> formats;

  const FormatSelector(
      {required this.provider, required this.formats, super.key});

  String _formatDisplayName(Map<String, dynamic> format) {
    final size = _formatSize(format['size'] as int? ?? 0);
    if (format['type'] == 'merge') {
      final video = format['video'] as Map<String, dynamic>;
      return 'Merge: ${video['resolution']} - $size';
    }
    return '${format['resolution']} - ${format['ext']} - $size';
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return 'Unknown';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var size = bytes.toDouble();
    var unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  bool _canToggleConversion() {
    final format = provider.selectedFormat;
    if (format == null || format['type'] == 'merge') return false;
    return format['needsConversion'] as bool? ?? false;
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
          items: formats
              .map((format) => DropdownMenuItem(
                    value: format,
                    child: Text(_formatDisplayName(format)),
                  ))
              .toList(),
          onChanged:
              provider.currentTask == null ? provider.selectFormat : null,
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
