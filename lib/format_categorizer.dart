// File: lib\format_categorizer.dart
import 'logger.dart';
import 'models.dart';

class FormatTypes {
  static const String videoWithSound = 'combined';
  static const String merge = 'merge';
  static const String audioOnly = 'audio_only';
}

class FormatCategorizer {
  List<Map<String, dynamic>> getFormatsByType(
      List<Map<String, dynamic>> formats, String formatType) {
    final seenFormatIds = <String>{}; // Track unique format IDs
    final categorized = <Map<String, dynamic>>[];

    for (final format in formats) {
      final vcodec = format['vcodec'] as String? ?? 'none';
      final acodec = format['acodec'] as String? ?? 'none';
      final formatId = format['formatId'] as String? ?? 'unknown';

      if (seenFormatIds.contains(formatId)) {
        PluginLogger.info('Skipping duplicate formatId: $formatId');
        continue;
      }

      if (formatType == FormatTypes.videoWithSound &&
          vcodec != 'none' &&
          acodec != 'none') {
        categorized.add({
          'formatId': formatId,
          'ext': format['ext'] as String? ?? 'unknown',
          'resolution': format['resolution'] as String? ?? 'unknown',
          'bitrate': (format['bitrate'] as num?)?.toInt() ?? 0,
          'size': (format['size'] as num?)?.toInt() ?? 0,
          'type': FormatTypes.videoWithSound,
          'needsConversion': (format['ext'] as String?) != 'mp4',
        });
        seenFormatIds.add(formatId);
      } else if (formatType == FormatTypes.audioOnly &&
          vcodec == 'none' &&
          acodec != 'none') {
        categorized.add({
          'formatId': formatId,
          'ext': format['ext'] as String? ?? 'unknown',
          'resolution': format['resolution'] as String? ?? 'unknown',
          'bitrate': (format['bitrate'] as num?)?.toInt() ?? 0,
          'size': (format['size'] as num?)?.toInt() ?? 0,
          'type': FormatTypes.audioOnly,
          'needsConversion': (format['ext'] as String?) != 'mp3',
        });
        seenFormatIds.add(formatId);
      } else if (formatType == FormatTypes.merge &&
          vcodec != 'none' &&
          acodec == 'none') {
        final audioFormats = formats
            .where((f) => f['vcodec'] == 'none' && f['acodec'] != 'none')
            .toList();
        for (final audio in audioFormats) {
          final mergeFormatId = '${formatId}+${audio['formatId']}';
          if (!seenFormatIds.contains(mergeFormatId)) {
            categorized.add({
              'type': FormatTypes.merge,
              'video': {
                'formatId': formatId,
                'ext': format['ext'] as String? ?? 'unknown',
                'resolution': format['resolution'] as String? ?? 'unknown',
                'bitrate': (format['bitrate'] as num?)?.toInt() ?? 0,
                'size': (format['size'] as num?)?.toInt() ?? 0,
              },
              'audio': {
                'formatId': audio['formatId'] as String? ?? 'unknown',
                'ext': audio['ext'] as String? ?? 'unknown',
                'resolution': audio['resolution'] as String? ?? 'unknown',
                'bitrate': (audio['bitrate'] as num?)?.toInt() ?? 0,
                'size': (audio['size'] as num?)?.toInt() ?? 0,
              },
              'formatId': mergeFormatId,
              'ext': 'mp4',
              'resolution': format['resolution'] as String? ?? 'unknown',
              'size': ((format['size'] as num?)?.toInt() ?? 0) +
                  ((audio['size'] as num?)?.toInt() ?? 0),
            });
            seenFormatIds.add(mergeFormatId);
          }
        }
      }
    }

    PluginLogger.info('Categorized $formatType formats: ${categorized.length}');
    return categorized;
  }
}
