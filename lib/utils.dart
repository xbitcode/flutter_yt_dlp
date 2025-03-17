import 'logger.dart';

String generateOutputPath(
  Map<String, dynamic> format,
  String outputDir,
  String videoTitle,
  String? overrideName,
  bool overwrite,
) {
  final baseName =
      (overrideName ?? videoTitle).replaceAll(RegExp(r'[^\w\s-]'), '').trim();
  String suffix;
  String ext;

  switch (format['type'] as String) {
    case 'combined':
      suffix = '${format['resolution']}_${format['bitrate']}kbps';
      ext = format['needsConversion'] as bool &&
              !(format['downloadAsRaw'] as bool? ?? true)
          ? 'mp4'
          : format['ext'] as String;
      break;
    case 'merge':
      final video = format['video'] as Map<String, dynamic>;
      final audio = format['audio'] as Map<String, dynamic>;
      suffix = '${video['resolution']}_${audio['bitrate']}kbps';
      ext = 'mp4';
      break;
    case 'audio_only':
      suffix = '${format['bitrate']}kbps';
      ext = format['needsConversion'] as bool &&
              !(format['downloadAsRaw'] as bool? ?? true)
          ? 'mp3'
          : format['ext'] as String;
      break;
    default:
      throw ArgumentError('Unknown format type: ${format['type']}');
  }

  String filePath = '$outputDir/${baseName}_$suffix.$ext';
  if (!overwrite) {
    filePath = _getUniqueFilePath(filePath);
  }
  PluginLogger.info('Generated path: $filePath');
  return filePath;
}

String _getUniqueFilePath(String basePath) {
  // Note: Actual file existence check requires platform-specific code.
  // This is a placeholder assuming uniqueness is handled on the native side.
  return basePath;
}

// New utility function to convert platform channel map to typed map
Map<String, dynamic> convertPlatformMap(dynamic input) {
  if (input is! Map) {
    throw ArgumentError('Expected a Map but got ${input.runtimeType}');
  }
  final result = <String, dynamic>{};
  for (final entry in input.entries) {
    final key = entry.key;
    if (key is! String) {
      PluginLogger.warning('Non-string key found in platform map: $key');
      continue; // Skip non-string keys
    }
    final value = entry.value;
    if (value is Map) {
      result[key] = convertPlatformMap(value);
    } else if (value is List) {
      result[key] = _convertList(value);
    } else {
      result[key] = value;
    }
  }
  return result;
}

List<dynamic> _convertList(List<dynamic> input) {
  return input.map((item) {
    if (item is Map) {
      return convertPlatformMap(item);
    } else if (item is List) {
      return _convertList(item);
    } else {
      return item;
    }
  }).toList();
}
