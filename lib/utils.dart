import 'package:logging/logging.dart';
import 'models.dart';

final Logger _logger = Logger('FlutterYtDlpPlugin');

/// Sets up logging for the plugin.
void setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
}

/// Generates an output file path based on the format type.
String generateOutputPath(
    dynamic format, String outputDir, String originalName) {
  final cleanName = originalName.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
  if (format is MergeFormat) {
    return "$outputDir/${cleanName}_${format.video.resolution ?? 'unknown'}_${format.audio.bitrate}kbps.mp4";
  } else if (format is CombinedFormat) {
    final ext = format.needsConversion ? 'mp4' : (format.ext ?? 'unknown');
    return "$outputDir/${cleanName}_${format.resolution ?? 'unknown'}_${format.bitrate}kbps.$ext";
  } else if (format is Format) {
    final ext = (format.ext != 'mp3') ? 'mp3' : (format.ext ?? 'unknown');
    return "$outputDir/${cleanName}_${format.resolution ?? 'unknown'}_${format.bitrate}kbps.$ext";
  }
  throw ArgumentError('Unsupported format type');
}

/// Converts a format object to a map for serialization.
Map<String, dynamic> convertFormatToMap(dynamic format) {
  if (format is MergeFormat) return format.toMap();
  if (format is CombinedFormat) return format.toMap();
  if (format is Format) return format.toMap();
  throw ArgumentError('Unsupported format type');
}
