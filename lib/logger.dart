import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

/// Manages logging for the Flutter YouTube Downloader plugin.
class PluginLogger {
  static final Logger _logger = Logger('FlutterYtDlpPlugin');
  static bool _isSetup = false;
  static bool _isInitializing = false;

  /// Ensures logging is set up without causing recursive stream conflicts.
  static void ensureSetup() {
    if (_isSetup || _isInitializing) return;
    _isInitializing = true; // Guard against reentrant calls
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen(_handleLogRecord);
    _isSetup = true;
    _isInitializing = false;
    // No initial log here to prevent recursion
  }

  /// Logs an info-level message.
  static void info(String message) {
    ensureSetup(); // Ensure logger is ready before logging
    _logger.info(message);
  }

  /// Logs a warning-level message.
  static void warning(String message) {
    ensureSetup();
    _logger.warning(message);
  }

  /// Logs an error-level message with optional details.
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    ensureSetup();
    _logger.severe(message, error, stackTrace);
  }

  /// Handles log records, avoiding recursion during initialization.
  static void _handleLogRecord(LogRecord record) {
    if (_isInitializing) return; // Skip logs during setup to prevent recursion
    final formatted = '${record.level.name}: ${record.time}: ${record.message}';
    // Use debugPrint instead of print to avoid lint warnings and ensure visibility
    debugPrint(formatted);
  }
}
