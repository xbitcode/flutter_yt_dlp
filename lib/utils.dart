import 'logger.dart';
import 'models.dart';

/// Generates an output file path based on format and metadata.
String generateOutputPath(
  dynamic format,
  String outputDir,
  String videoTitle,
  String? overrideName,
) {
  final baseName =
      overrideName ?? videoTitle.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
  String filePath;

  if (format is MergeFormat) {
    final resolution = format.video.resolution ?? 'unknown';
    final bitrate = format.audio.bitrate;
    filePath = "$outputDir/${baseName}_${resolution}_${bitrate}kbps.mp4";
  } else if (format is CombinedFormat) {
    final ext = format.needsConversion ? 'mp4' : (format.ext ?? 'unknown');
    final resolution = format.resolution ?? 'unknown';
    final bitrate = format.bitrate;
    filePath = "$outputDir/${baseName}_${resolution}_${bitrate}kbps.$ext";
  } else if (format is Format) {
    final ext = format.ext == 'mp3' ? 'mp3' : 'mp3';
    final resolution = format.resolution ?? 'unknown';
    final bitrate = format.bitrate;
    filePath = "$outputDir/${baseName}_${resolution}_${bitrate}kbps.$ext";
  } else {
    throw ArgumentError('Unsupported format type');
  }

  PluginLogger.info('Generated output path: $filePath');
  return filePath;
}

/// Converts a format object to a map representation.
Map<String, dynamic> convertFormatToMap(dynamic format) {
  if (format is MergeFormat) return format.toMap();
  if (format is CombinedFormat) return format.toMap();
  if (format is Format) return format.toMap();
  throw ArgumentError('Unsupported format type');
}
