import 'package:logger/logger.dart';

/// App-wide logger
class AppLogger {
  AppLogger._();

  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
      noBoxingByDefault: false,
    ),
  );

  static const _shouldLog = true; // Can be set based on kDebugMode if needed

  /// Log debug message
  static void d(String message, [Object? error, StackTrace? stackTrace]) {
    if (_shouldLog) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log info message
  static void i(String message, [Object? error, StackTrace? stackTrace]) {
    if (_shouldLog) {
      _logger.i(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log warning message
  static void w(String message, [Object? error, StackTrace? stackTrace]) {
    if (_shouldLog) {
      _logger.w(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log error message
  static void e(String message, [Object? error, StackTrace? stackTrace]) {
    if (_shouldLog) {
      _logger.e(message, error: error, stackTrace: stackTrace);
    }
  }

  /// Log trace/verbose message
  static void t(String message, [Object? error, StackTrace? stackTrace]) {
    if (_shouldLog) {
      _logger.t(message, error: error, stackTrace: stackTrace);
    }
  }
}
