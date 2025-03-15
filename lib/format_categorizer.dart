import 'models.dart';

class FormatCategorizer {
  List<Map<String, dynamic>> getRawVideoWithSoundFormats(
      List<Map<String, dynamic>> formats) {
    return formats
        .where((f) =>
            f['vcodec'] != null &&
            f['vcodec'] != 'none' &&
            f['acodec'] != null &&
            f['acodec'] != 'none')
        .map((f) => CombinedFormat(
              formatId: f['format_id'] as String?,
              ext: f['ext'] as String? ?? 'unknown',
              resolution: f['resolution'] as String? ?? 'unknown',
              bitrate: (f['tbr'] as num?)?.toInt() ?? 0,
              size: (f['filesize'] as num?)?.toInt() ?? 0,
              needsConversion: (f['ext'] as String?) !=
                  'mp4', // Conversion needed if not mp4
            ).toMap())
        .toList();
  }

  List<Map<String, dynamic>> getMergeFormats(
      List<Map<String, dynamic>> formats) {
    final videoOnly = formats
        .where((f) => f['vcodec'] != 'none' && f['acodec'] == 'none')
        .map((f) => Format(
              formatId: f['format_id'] as String?,
              ext: f['ext'] as String? ?? 'unknown',
              resolution: f['resolution'] as String? ?? 'unknown',
              bitrate: (f['tbr'] as num?)?.toInt() ?? 0,
              size: (f['filesize'] as num?)?.toInt() ?? 0,
            ))
        .toList();
    final audioOnly = formats
        .where((f) => f['vcodec'] == 'none' && f['acodec'] != 'none')
        .map((f) => Format(
              formatId: f['format_id'] as String?,
              ext: f['ext'] as String? ?? 'unknown',
              resolution: f['resolution'] as String? ?? 'unknown',
              bitrate: (f['tbr'] as num?)?.toInt() ?? 0,
              size: (f['filesize'] as num?)?.toInt() ?? 0,
            ))
        .toList();

    return videoOnly
        .map((video) => audioOnly
            .map((audio) => MergeFormat(video: video, audio: audio).toMap()))
        .expand((e) => e)
        .toList();
  }

  List<Map<String, dynamic>> getRawAudioOnlyFormats(
      List<Map<String, dynamic>> formats) {
    return formats
        .where((f) => f['vcodec'] == 'none' && f['acodec'] != 'none')
        .map((f) => CombinedFormat(
              formatId: f['format_id'] as String?,
              ext: f['ext'] as String? ?? 'unknown',
              resolution: f['resolution'] as String? ?? 'unknown',
              bitrate: (f['tbr'] as num?)?.toInt() ?? 0,
              size: (f['filesize'] as num?)?.toInt() ?? 0,
              needsConversion: (f['ext'] as String?) !=
                  'mp3', // Conversion needed if not mp3
            ).toMap())
        .toList();
  }
}
