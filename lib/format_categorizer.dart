import 'logger.dart';

/// Defines format type constants for video categorization.
class FormatTypes {
  /// Represents combined video and audio formats.
  static const String videoWithSound = 'combined';

  /// Represents formats requiring video and audio merging.
  static const String merge = 'merge';

  /// Represents audio-only formats.
  static const String audioOnly = 'audio_only';
}

/// Categorizes video formats into predefined types.
class FormatCategorizer {
  /// Filters and categorizes formats based on the specified type.
  ///
  /// [formats] The list of format maps to categorize.
  /// [formatType] The type of formats to extract (e.g., videoWithSound, merge, audioOnly).
  /// Returns a list of categorized format maps.
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
            'size': totalSize,
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
