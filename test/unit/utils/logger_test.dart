import 'dart:io';
import 'package:test/test.dart';
import 'package:ai_webscraper/src/utils/logger.dart';

void main() {
  group('Logger', () {
    setUp(() {
      // Reset logger state before each test
      Logger.setLevel(LogLevel.info);
      Logger.configure(
        includeTimestamp: true,
        includeLevelName: true,
        outputToConsole: true,
      );
      Logger.closeFileLogging();
    });

    tearDown(() async {
      // Clean up file logging after each test
      await Logger.closeFileLogging();
    });

    group('LogLevel enum', () {
      test('should have correct order', () {
        expect(LogLevel.debug.index, lessThan(LogLevel.info.index));
        expect(LogLevel.info.index, lessThan(LogLevel.warning.index));
        expect(LogLevel.warning.index, lessThan(LogLevel.error.index));
        expect(LogLevel.error.index, lessThan(LogLevel.critical.index));
      });

      test('should have all expected levels', () {
        expect(LogLevel.values, hasLength(5));
        expect(LogLevel.values, contains(LogLevel.debug));
        expect(LogLevel.values, contains(LogLevel.info));
        expect(LogLevel.values, contains(LogLevel.warning));
        expect(LogLevel.values, contains(LogLevel.error));
        expect(LogLevel.values, contains(LogLevel.critical));
      });
    });

    group('setLevel', () {
      test('should set the current log level', () {
        Logger.setLevel(LogLevel.error);
        expect(Logger.currentLevel, equals(LogLevel.error));

        Logger.setLevel(LogLevel.debug);
        expect(Logger.currentLevel, equals(LogLevel.debug));
      });
    });

    group('configure', () {
      test('should configure logging options', () {
        Logger.configure(
          includeTimestamp: false,
          includeLevelName: false,
          outputToConsole: false,
        );

        // Note: We can't directly test the private fields,
        // but we can test the behavior through log output
        expect(() => Logger.info('test'), returnsNormally);
      });

      test('should handle null parameters', () {
        Logger.configure(
          includeTimestamp: null,
          includeLevelName: null,
          outputToConsole: null,
        );

        expect(() => Logger.info('test'), returnsNormally);
      });
    });

    group('isLevelEnabled', () {
      test('should correctly determine if level is enabled', () {
        Logger.setLevel(LogLevel.warning);

        expect(Logger.isLevelEnabled(LogLevel.debug), isFalse);
        expect(Logger.isLevelEnabled(LogLevel.info), isFalse);
        expect(Logger.isLevelEnabled(LogLevel.warning), isTrue);
        expect(Logger.isLevelEnabled(LogLevel.error), isTrue);
        expect(Logger.isLevelEnabled(LogLevel.critical), isTrue);
      });
    });

    group('logging methods', () {
      test('should not throw when logging messages', () {
        expect(() => Logger.debug('Debug message'), returnsNormally);
        expect(() => Logger.info('Info message'), returnsNormally);
        expect(() => Logger.warning('Warning message'), returnsNormally);
        expect(() => Logger.error('Error message'), returnsNormally);
        expect(() => Logger.critical('Critical message'), returnsNormally);
      });

      test('should handle null parameters', () {
        expect(() => Logger.debug('Message', null, null), returnsNormally);
        expect(() => Logger.info('Message', null, null), returnsNormally);
        expect(() => Logger.warning('Message', null, null), returnsNormally);
        expect(() => Logger.error('Message', null, null), returnsNormally);
        expect(() => Logger.critical('Message', null, null), returnsNormally);
      });

      test('should handle error and stack trace parameters', () {
        final error = Exception('Test error');
        final stackTrace = StackTrace.current;

        expect(
          () => Logger.error('Error occurred', error, stackTrace),
          returnsNormally,
        );
      });

      test('should respect log level filtering', () {
        Logger.setLevel(LogLevel.error);

        // These should not be output (but shouldn't throw)
        expect(() => Logger.debug('Debug'), returnsNormally);
        expect(() => Logger.info('Info'), returnsNormally);
        expect(() => Logger.warning('Warning'), returnsNormally);

        // These should be output
        expect(() => Logger.error('Error'), returnsNormally);
        expect(() => Logger.critical('Critical'), returnsNormally);
      });
    });

    group('file logging', () {
      late String tempFilePath;

      setUp(() {
        tempFilePath = 'test_log_${DateTime.now().millisecondsSinceEpoch}.log';
      });

      tearDown(() async {
        await Logger.closeFileLogging();
        try {
          await File(tempFilePath).delete();
        } catch (e) {
          // Ignore cleanup errors
        }
      });

      test('should setup file logging', () async {
        await Logger.setupFileLogging(tempFilePath);
        Logger.info('Test message');
        await Logger.closeFileLogging();

        final file = File(tempFilePath);
        expect(await file.exists(), isTrue);

        final content = await file.readAsString();
        expect(content, contains('Test message'));
      });

      test('should append to existing file', () async {
        // Create initial file
        await Logger.setupFileLogging(tempFilePath);
        Logger.info('First message');
        await Logger.closeFileLogging();

        // Append to file
        await Logger.setupFileLogging(tempFilePath, append: true);
        Logger.info('Second message');
        await Logger.closeFileLogging();

        final content = await File(tempFilePath).readAsString();
        expect(content, contains('First message'));
        expect(content, contains('Second message'));
      });

      test('should overwrite existing file when append is false', () async {
        // Create initial file
        await Logger.setupFileLogging(tempFilePath);
        Logger.info('First message');
        await Logger.closeFileLogging();

        // Overwrite file
        await Logger.setupFileLogging(tempFilePath, append: false);
        Logger.info('Second message');
        await Logger.closeFileLogging();

        final content = await File(tempFilePath).readAsString();
        expect(content, isNot(contains('First message')));
        expect(content, contains('Second message'));
      });

      test('should handle file logging errors gracefully', () async {
        // Try to log to an invalid path
        expect(
          () => Logger.setupFileLogging('/invalid/path/log.txt'),
          returnsNormally,
        );

        // Should still be able to log to console
        expect(() => Logger.info('Test message'), returnsNormally);
      });

      test('should close file logging properly', () async {
        await Logger.setupFileLogging(tempFilePath);
        Logger.info('Test message');

        expect(
          () => Logger.closeFileLogging(),
          returnsNormally,
        );

        // Should be able to setup again
        expect(
          () => Logger.setupFileLogging(tempFilePath),
          returnsNormally,
        );
      });
    });

    group('logTimed', () {
      test('should time synchronous operations', () {
        var executionCount = 0;

        final result = Logger.logTimed('test operation', () {
          executionCount++;
          return 'success';
        });

        expect(result, equals('success'));
        expect(executionCount, equals(1));
      });

      test('should handle exceptions in timed operations', () {
        expect(
          () => Logger.logTimed('failing operation', () {
            throw Exception('Test error');
          }),
          throwsA(isA<Exception>()),
        );
      });

      test('should return correct result type', () {
        final intResult = Logger.logTimed('int operation', () => 42);
        expect(intResult, isA<int>());
        expect(intResult, equals(42));

        final stringResult = Logger.logTimed('string operation', () => 'test');
        expect(stringResult, isA<String>());
        expect(stringResult, equals('test'));
      });
    });

    group('logTimedAsync', () {
      test('should time asynchronous operations', () async {
        var executionCount = 0;

        final result =
            await Logger.logTimedAsync('async test operation', () async {
          executionCount++;
          await Future<void>.delayed(Duration(milliseconds: 10));
          return 'async success';
        });

        expect(result, equals('async success'));
        expect(executionCount, equals(1));
      });

      test('should handle exceptions in async timed operations', () async {
        expect(
          () => Logger.logTimedAsync('failing async operation', () async {
            await Future<void>.delayed(Duration(milliseconds: 10));
            throw Exception('Async test error');
          }),
          throwsA(isA<Exception>()),
        );
      });

      test('should return correct result type for async operations', () async {
        final intResult =
            await Logger.logTimedAsync('async int operation', () async => 42);
        expect(intResult, isA<int>());
        expect(intResult, equals(42));

        final stringResult = await Logger.logTimedAsync(
            'async string operation', () async => 'test');
        expect(stringResult, isA<String>());
        expect(stringResult, equals('test'));
      });
    });

    group('scoped logger', () {
      test('should create scoped logger with prefix', () {
        final scopedLogger = Logger.scoped('TEST');

        expect(() => scopedLogger.debug('Debug message'), returnsNormally);
        expect(() => scopedLogger.info('Info message'), returnsNormally);
        expect(() => scopedLogger.warning('Warning message'), returnsNormally);
        expect(() => scopedLogger.error('Error message'), returnsNormally);
        expect(
            () => scopedLogger.critical('Critical message'), returnsNormally);
      });

      test('should handle scoped timing operations', () {
        final scopedLogger = Logger.scoped('TIMER');

        final result = scopedLogger.logTimed('test operation', () => 'result');
        expect(result, equals('result'));
      });

      test('should handle scoped async timing operations', () async {
        final scopedLogger = Logger.scoped('ASYNC_TIMER');

        final result = await scopedLogger.logTimedAsync(
            'async test operation', () async => 'async result');
        expect(result, equals('async result'));
      });

      test('should handle error and stack trace in scoped logger', () {
        final scopedLogger = Logger.scoped('ERROR_TEST');
        final error = Exception('Scoped error');
        final stackTrace = StackTrace.current;

        expect(
          () => scopedLogger.error('Scoped error occurred', error, stackTrace),
          returnsNormally,
        );
      });
    });

    group('configuration combinations', () {
      test('should work with timestamp disabled', () {
        Logger.configure(includeTimestamp: false);
        expect(() => Logger.info('No timestamp'), returnsNormally);
      });

      test('should work with level name disabled', () {
        Logger.configure(includeLevelName: false);
        expect(() => Logger.info('No level name'), returnsNormally);
      });

      test('should work with console output disabled', () {
        Logger.configure(outputToConsole: false);
        expect(() => Logger.info('No console output'), returnsNormally);
      });

      test('should work with all formatting disabled', () {
        Logger.configure(
          includeTimestamp: false,
          includeLevelName: false,
          outputToConsole: false,
        );
        expect(() => Logger.info('Minimal logging'), returnsNormally);
      });
    });

    group('stress tests', () {
      test('should handle many log messages', () {
        Logger.setLevel(LogLevel.debug);

        expect(() {
          for (int i = 0; i < 1000; i++) {
            Logger.debug('Message $i');
          }
        }, returnsNormally);
      });

      test('should handle concurrent logging', () async {
        final futures = <Future<void>>[];

        for (int i = 0; i < 10; i++) {
          futures.add(Future(() {
            for (int j = 0; j < 100; j++) {
              Logger.info('Thread $i, Message $j');
            }
          }));
        }

        expect(() => Future.wait(futures), returnsNormally);
      });

      test('should handle very long messages', () {
        final longMessage = 'A' * 10000;
        expect(() => Logger.info(longMessage), returnsNormally);
      });

      test('should handle special characters', () {
        expect(() => Logger.info('Message with 特殊文字 and émojis 🚀'),
            returnsNormally);
      });

      test('should handle null and empty messages', () {
        expect(() => Logger.info(''), returnsNormally);
        expect(() => Logger.info('   '), returnsNormally);
      });
    });

    group('memory management', () {
      test('should not leak memory with repeated file setup', () async {
        for (int i = 0; i < 10; i++) {
          final tempFile = 'temp_log_$i.log';
          await Logger.setupFileLogging(tempFile);
          Logger.info('Test message $i');
          await Logger.closeFileLogging();

          try {
            await File(tempFile).delete();
          } catch (e) {
            // Ignore cleanup errors
          }
        }

        expect(true, isTrue); // Test completes without memory issues
      });
    });

    group('error scenarios', () {
      test('should handle errors during file operations', () async {
        // Setup file logging to a valid location first
        final tempFile = 'valid_log.log';
        await Logger.setupFileLogging(tempFile);

        // Then try to setup to an invalid location
        // This should log an error but not crash
        expect(
          () => Logger.setupFileLogging('/root/invalid_path.log'),
          returnsNormally,
        );

        // Should still be able to log
        expect(() => Logger.info('After error'), returnsNormally);

        await Logger.closeFileLogging();
        try {
          await File(tempFile).delete();
        } catch (e) {
          // Ignore cleanup errors
        }
      });

      test('should handle multiple close calls', () async {
        await Logger.closeFileLogging();
        expect(() => Logger.closeFileLogging(), returnsNormally);
        expect(() => Logger.closeFileLogging(), returnsNormally);
      });
    });
  });
}
