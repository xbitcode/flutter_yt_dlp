import 'package:logging/logging.dart';

/// Manages logging for the Flutter YouTube Downloader plugin.
class PluginLogger {
  static final Logger _logger = Logger('FlutterYtDlpPlugin');
  static bool _isSetup = false;
  static bool _isInitializing = false;

  /// Configures the logging system to capture all log levels.
  static void setup() {
    if (_isSetup || _isInitializing) return;
    _isInitializing = true; // Prevent reentrant calls during setup
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen(_handleLogRecord);
    _isSetup = true;
    _isInitializing = false;
    // No initial log to avoid recursion; rely on first client log
  }

  /// Logs an info-level message.
  static void info(String message) => _logger.info(message);

  /// Logs a warning-level message.
  static void warning(String message) => _logger.warning(message);

  /// Logs an error-level message with optional details.
  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.severe(message, error, stackTrace);

  static void _handleLogRecord(LogRecord record) {
    if (_isInitializing) return; // Skip logs during setup
    _logger.info('${record.level.name}: ${record.time}: ${record.message}');
  }
}
