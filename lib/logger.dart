import 'package:logging/logging.dart';

class PluginLogger {
  static final Logger _logger = Logger('FlutterYtDlpPlugin');
  static bool _isSetup = false;

  static void setup() {
    if (_isSetup) return;
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
    _isSetup = true;
    _logger.info('Logging initialized');
  }

  static void info(String message) => _logger.info(message);
  static void warning(String message) => _logger.warning(message);
  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.severe(message, error, stackTrace);
}
