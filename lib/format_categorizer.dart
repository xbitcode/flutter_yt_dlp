import 'models.dart';

/// Categorizes media formats into specific types for download.
class FormatCategorizer {
  /// Retrieves formats based on the specified [formatType].
  List<Map<String, dynamic>> getFormatsByType(
      List<Map<String, dynamic>> formats, String formatType) {
    switch (formatType) {
      case FormatTypes.videoWithSound:
        return _getVideoWithSoundFormats(formats);
      case FormatTypes.merge:
        return _getMergeFormats(formats);
      case FormatTypes.audioOnly:
        return _getAudioOnlyFormats(formats);
      default:
        return [];
    }
  }

  List<Map<String, dynamic>> _getVideoWithSoundFormats(
      List<Map<String, dynamic>> formats) {
    return formats
        .where((f) => f['vcodec'] != 'none' && f['acodec'] != 'none')
        .map((f) => CombinedFormat(
              formatId: f['formatId'] as String?,
              ext: f['ext'] as String? ?? 'unknown',
              resolution: f['resolution'] as String? ?? 'unknown',
              bitrate: (f['tbr'] as num?)?.toInt() ?? 0,
              size: (f['filesize'] as num?)?.toInt() ?? 0,
              needsConversion: (f['ext'] as String?) != 'mp4',
            ).toMap())
        .toList();
  }

  List<Map<String, dynamic>> _getMergeFormats(
      List<Map<String, dynamic>> formats) {
    final videoOnly = _getVideoOnlyFormats(formats);
    final audioOnly = _getAudioOnlyFormats(formats);
    return videoOnly
        .map((video) => audioOnly.map((audio) => MergeFormat(
              video: Format.fromMap(video),
              audio: Format.fromMap(audio.cast<String, dynamic>()),
            ).toMap()))
        .expand((e) => e)
        .toList();
  }

  List<Map<String, dynamic>> _getAudioOnlyFormats(
      List<Map<String, dynamic>> formats) {
    return formats
        .where((f) => f['vcodec'] == 'none' && f['acodec'] != 'none')
        .map((f) => CombinedFormat(
              formatId: f['formatId'] as String?,
              ext: f['ext'] as String? ?? 'unknown',
              resolution: f['resolution'] as String? ?? 'unknown',
              bitrate: (f['tbr'] as num?)?.toInt() ?? 0,
              size: (f['filesize'] as num?)?.toInt() ?? 0,
              needsConversion: (f['ext'] as String?) != 'mp3',
            ).toMap())
        .toList();
  }

  List<Map<String, dynamic>> _getVideoOnlyFormats(
      List<Map<String, dynamic>> formats) {
    return formats
        .where((f) => f['vcodec'] != 'none' && f['acodec'] == 'none')
        .map((f) => Format(
              formatId: f['formatId'] as String?,
              ext: f['ext'] as String? ?? 'unknown',
              resolution: f['resolution'] as String? ?? 'unknown',
              bitrate: (f['tbr'] as num?)?.toInt() ?? 0,
              size: (f['filesize'] as num?)?.toInt() ?? 0,
            ).toMap())
        .toList();
  }
}
