import 'logger.dart';

class FormatTypes {
  static const String videoWithSound = 'combined';
  static const String merge = 'merge';
  static const String audioOnly = 'audio_only';
}

class FormatCategorizer {
  List<Map<String, dynamic>> getFormatsByType(
      List<Map<String, dynamic>> formats, String formatType) {
    final categorized = <Map<String, dynamic>>[];
    final seenFormatIds = <String>{};

    final combined = formats
        .where((f) => f['vcodec'] != 'none' && f['acodec'] != 'none')
        .toList();
    final videoOnly = formats
        .where((f) => f['vcodec'] != 'none' && f['acodec'] == 'none')
        .toList();
    final audioOnly = formats
        .where((f) => f['vcodec'] == 'none' && f['acodec'] != 'none')
        .toList();

    if (formatType == FormatTypes.videoWithSound) {
      for (final format in combined) {
        final formatId = format['formatId'] as String;
        if (seenFormatIds.add(formatId)) {
          categorized.add({
            ...format,
            'type': FormatTypes.videoWithSound,
            'needsConversion': (format['ext'] as String?) != 'mp4',
          });
        }
      }
    } else if (formatType == FormatTypes.merge && audioOnly.isNotEmpty) {
      audioOnly
          .sort((a, b) => (b['bitrate'] as int).compareTo(a['bitrate'] as int));
      final bestAudio = audioOnly.first;
      for (final video in videoOnly) {
        final mergeFormatId = '${video['formatId']}+${bestAudio['formatId']}';
        if (seenFormatIds.add(mergeFormatId)) {
          final videoSize = video['size'] as int? ?? 0;
          final audioSize = bestAudio['size'] as int? ?? 0;
          final totalSize =
              (videoSize > 0 && audioSize > 0) ? videoSize + audioSize : null;
          categorized.add({
            'type': FormatTypes.merge,
            'video': video,
            'audio': bestAudio,
            'formatId': mergeFormatId,
            'ext': 'mp4',
            'resolution': video['resolution'] as String? ?? 'unknown',
            'size': totalSize, // Set to null if either size is unknown
          });
        }
      }
    } else if (formatType == FormatTypes.audioOnly) {
      for (final format in audioOnly) {
        final formatId = format['formatId'] as String;
        if (seenFormatIds.add(formatId)) {
          categorized.add({
            ...format,
            'type': FormatTypes.audioOnly,
            'needsConversion': (format['ext'] as String?) != 'mp3',
          });
        }
      }
    }

    PluginLogger.info('Categorized $formatType formats: ${categorized.length}');
    return categorized;
  }
}
