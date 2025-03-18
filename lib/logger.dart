import 'package:logging/logging.dart';

/// A utility class for logging plugin activities.
class PluginLogger {
  static final Logger _logger = Logger('FlutterYtDlpPlugin');
  static bool _isSetup = false;

  /// Sets up the logging system with detailed output.
  ///
  /// Configures the root logger to capture all levels and directs log records
  /// to the plugin's logger instance after initialization.
  static void setup() {
    if (_isSetup) return;
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      _logger.info('${record.level.name}: ${record.time}: ${record.message}');
    });
    _isSetup = true;
    // Removed _logSetupMessage() to prevent recursion during setup
  }

  /// Logs an informational message.
  ///
  /// [message] The message to log.
  static void info(String message) => _logger.info(message);

  /// Logs a warning message.
  ///
  /// [message] The warning to log.
  static void warning(String message) => _logger.warning(message);

  /// Logs an error message with optional error and stack trace.
  ///
  /// [message] The error message to log.
  /// [error] The associated error object, if any.
  /// [stackTrace] The stack trace, if any.
  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.severe(message, error, stackTrace);
}
