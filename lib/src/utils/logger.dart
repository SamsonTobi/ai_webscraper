// ignore_for_file: use_setters_to_change_properties

import 'dart:io';

/// Log levels for controlling logging output.
enum LogLevel {
  /// Debug information - most verbose
  debug,

  /// General information
  info,

  /// Warning messages
  warning,

  /// Error messages
  error,

  /// Critical errors
  critical,
}

/// Simple logging utility for the AI WebScraper package.
///
/// Provides basic logging functionality with different log levels
/// and configurable output destinations.
class Logger {
  /// The current minimum log level to output.
  static LogLevel _currentLevel = LogLevel.info;

  /// Whether to include timestamps in log messages.
  static bool _includeTimestamp = true;

  /// Whether to include log level names in messages.
  static bool _includeLevelName = true;

  /// Whether to output to console.
  static bool _outputToConsole = true;

  /// Optional file sink for logging to file.
  static IOSink? _fileSink;

  /// Sets the minimum log level.
  ///
  /// Only messages at this level or higher will be output.
  static void setLevel(LogLevel level) {
    _currentLevel = level;
  }

  /// Configures logging options.
  ///
  /// [includeTimestamp] - Whether to include timestamps
  /// [includeLevelName] - Whether to include log level names
  /// [outputToConsole] - Whether to output to console
  static void configure({
    bool? includeTimestamp,
    bool? includeLevelName,
    bool? outputToConsole,
  }) {
    if (includeTimestamp != null) {
      _includeTimestamp = includeTimestamp;
    }
    if (includeLevelName != null) {
      _includeLevelName = includeLevelName;
    }
    if (outputToConsole != null) {
      _outputToConsole = outputToConsole;
    }
  }

  /// Sets up file logging.
  ///
  /// [filePath] - Path to the log file
  /// [append] - Whether to append to existing file or overwrite
  static Future<void> setupFileLogging(String filePath,
      {bool append = true}) async {
    try {
      await _fileSink?.close();
      _fileSink = null;
      final File file = File(filePath);
      _fileSink =
          file.openWrite(mode: append ? FileMode.append : FileMode.write);
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      // Ensure _fileSink is null on error to prevent further issues
      _fileSink = null;
      // Log error to console only to avoid recursive file logging issues
      if (_outputToConsole) {
        stderr.writeln('[ERROR] Failed to setup file logging: $e');
      }
    }
  }

  /// Closes file logging resources.
  static Future<void> closeFileLogging() async {
    try {
      await _fileSink?.close();
    } on FormatException catch (e) {
      // Ignore errors when closing, but still null out the reference
      if (_outputToConsole) {
        stderr.writeln('[ERROR] Error closing file sink: $e');
      }
    } finally {
      _fileSink = null;
    }
  }

  /// Logs a debug message.
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  /// Logs an info message.
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  /// Logs a warning message.
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  /// Logs an error message.
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  /// Logs a critical error message.
  static void critical(String message,
      [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.critical, message, error, stackTrace);
  }

  /// Internal logging method.
  static void _log(
      LogLevel level, String message, Object? error, StackTrace? stackTrace) {
    // Check if we should log this level
    if (level.index < _currentLevel.index) {
      return;
    }

    final StringBuffer buffer = StringBuffer();

    // Add timestamp if enabled
    if (_includeTimestamp) {
      buffer.write('[${DateTime.now().toIso8601String()}] ');
    }

    // Add level name if enabled
    if (_includeLevelName) {
      buffer.write('[${_getLevelName(level)}] ');
    }

    // Add the main message
    buffer.write(message);

    // Add error details if provided
    if (error != null) {
      buffer.write(' | Error: $error');
    }

    final String logMessage = buffer.toString();

    // Output to console if enabled
    if (_outputToConsole) {
      if (level == LogLevel.error || level == LogLevel.critical) {
        stderr.writeln(logMessage);
      } else {
        stdout.writeln(logMessage);
      }
    }

    // Output to file if configured
    if (_fileSink != null) {
      try {
        _fileSink!.writeln(logMessage);
        if (stackTrace != null) {
          _fileSink!.writeln('Stack trace: $stackTrace');
        }
      } on FormatException catch (e) {
        // If file logging fails, close the sink and continue with console logging only
        try {
          _fileSink?.close();
        } on FormatException catch (_) {
          // Ignore errors when closing after a failure
        }
        _fileSink = null;
        if (_outputToConsole) {
          stderr.writeln(
              '[ERROR] File logging failed, continuing with console only: $e');
        }
      }
    }

    // Print stack trace to console for errors
    if (_outputToConsole &&
        stackTrace != null &&
        (level == LogLevel.error || level == LogLevel.critical)) {
      stderr.writeln('Stack trace: $stackTrace');
    }
  }

  /// Gets a human-readable name for a log level.
  static String _getLevelName(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
      case LogLevel.critical:
        return 'CRITICAL';
    }
  }

  /// Gets the current log level.
  static LogLevel get currentLevel => _currentLevel;

  /// Checks if a log level is enabled.
  // ignore: lines_longer_than_80_chars
  static bool isLevelEnabled(LogLevel level) =>
      level.index >= _currentLevel.index;

  /// Utility method for timing operations with automatic logging.
  ///
  /// [operation] - The operation name to log
  /// [function] - The function to time
  ///
  /// Returns the result of the function.
  static T logTimed<T>(String operation, T Function() function) {
    final Stopwatch stopwatch = Stopwatch()..start();
    debug('Starting $operation');

    try {
      // ignore: always_specify_types
      final result = function();
      stopwatch.stop();
      info('Completed $operation in ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e, stackTrace) {
      stopwatch.stop();
      error('Failed $operation after ${stopwatch.elapsedMilliseconds}ms', e,
          stackTrace);
      rethrow;
    }
  }

  /// Utility method for timing async operations with automatic logging.
  ///
  /// [operation] - The operation name to log
  /// [function] - The async function to time
  ///
  /// Returns the result of the function.
  static Future<T> logTimedAsync<T>(
      String operation, Future<T> Function() function) async {
    final Stopwatch stopwatch = Stopwatch()..start();
    debug('Starting $operation');

    try {
      final T result = await function();
      stopwatch.stop();
      info('Completed $operation in ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e, stackTrace) {
      stopwatch.stop();
      error('Failed $operation after ${stopwatch.elapsedMilliseconds}ms', e,
          stackTrace);
      rethrow;
    }
  }

  /// Creates a scoped logger with a prefix.
  ///
  /// Useful for adding context to log messages within a specific scope.
  static ScopedLogger scoped(String prefix) => ScopedLogger._(prefix);
}

/// A scoped logger that adds a prefix to all log messages.
class ScopedLogger {
  ScopedLogger._(this._prefix);
  final String _prefix;

  /// Logs a debug message with the scope prefix.
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    Logger.debug('$_prefix: $message', error, stackTrace);
  }

  /// Logs an info message with the scope prefix.
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    Logger.info('$_prefix: $message', error, stackTrace);
  }

  /// Logs a warning message with the scope prefix.
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    Logger.warning('$_prefix: $message', error, stackTrace);
  }

  /// Logs an error message with the scope prefix.
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    Logger.error('$_prefix: $message', error, stackTrace);
  }

  /// Logs a critical error message with the scope prefix.
  void critical(String message, [Object? error, StackTrace? stackTrace]) {
    Logger.critical('$_prefix: $message', error, stackTrace);
  }

  /// Times an operation with the scope prefix.
  T logTimed<T>(String operation, T Function() function) {
    return Logger.logTimed('$_prefix: $operation', function);
  }

  /// Times an async operation with the scope prefix.
  Future<T> logTimedAsync<T>(String operation, Future<T> Function() function) {
    return Logger.logTimedAsync('$_prefix: $operation', function);
  }
}
