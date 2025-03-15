import 'package:logging/logging.dart';

/// Provides logging utilities for the FlutterYtDlp plugin.
class PluginLogger {
  static final Logger _logger = Logger('FlutterYtDlpPlugin');
  static bool _isSetup = false;

  /// Sets up logging with a default configuration.
  static void setup() {
    if (_isSetup) return; // Prevent multiple setups
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // Use print temporarily to avoid reentrancy; replace with a proper output in production
      print('${record.level.name}: ${record.time}: ${record.message}');
    });
    _isSetup = true;
    // Log initialization asynchronously to avoid reentrancy
    Future.microtask(
        () => _logger.info('Logging initialized for FlutterYtDlpPlugin'));
  }

  /// Logs an informational message.
  static void info(String message) => _logger.info(message);

  /// Logs a warning message.
  static void warning(String message) => _logger.warning(message);

  /// Logs an error message with optional error and stack trace.
  static void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _logger.severe(message, error, stackTrace);
}
