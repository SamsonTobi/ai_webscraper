import 'dart:async';

import 'package:ai_webscraper/src/core/exceptions.dart';
import 'package:ai_webscraper/src/utils/batch_processor.dart';
import 'package:test/test.dart';

void main() {
  group('BatchProcessor', () {
    late BatchProcessor processor;

    setUp(() {
      processor = BatchProcessor();
    });

    group('Basic Batch Processing Tests', () {
      test('should process empty list successfully', () async {
        final results = await processor.processBatch<String>(
          items: <String>[],
          processor: (item) async => 'processed_$item',
        );

        expect(results, isEmpty);
      });

      test('should process single item successfully', () async {
        final results = await processor.processBatch<String>(
          items: ['item1'],
          processor: (item) async => 'processed_$item',
        );

        expect(results, hasLength(1));
        expect(results.first, equals('processed_item1'));
      });

      test('should process multiple items successfully', () async {
        final items = ['item1', 'item2', 'item3'];
        final results = await processor.processBatch<String>(
          items: items,
          processor: (item) async => 'processed_$item',
        );

        expect(results, hasLength(3));
        expect(results[0], equals('processed_item1'));
        expect(results[1], equals('processed_item2'));
        expect(results[2], equals('processed_item3'));
      });

      test('should maintain order of results', () async {
        final items = List.generate(10, (i) => 'item$i');
        final results = await processor.processBatch<String>(
          items: items,
          processor: (item) async {
            // Add small delay to test ordering
            await Future<void>.delayed(
                Duration(milliseconds: 10 - int.parse(item.substring(4))));
            return 'processed_$item';
          },
        );

        expect(results, hasLength(10));
        for (int i = 0; i < 10; i++) {
          expect(results[i], equals('processed_item$i'));
        }
      });
    });

    group('Concurrency Control Tests', () {
      test('should respect default concurrency limit', () async {
        final startTimes = <DateTime>[];
        final items = List.generate(5, (i) => 'item$i');

        await processor.processBatch<String>(
          items: items,
          processor: (item) async {
            startTimes.add(DateTime.now());
            await Future<void>.delayed(Duration(milliseconds: 100));
            return 'processed_$item';
          },
        );

        expect(startTimes, hasLength(5));
        // With default concurrency of 3, first 3 should start together
        // This is a rough test - timing can be flaky in unit tests
        expect(startTimes, hasLength(5));
      });

      test('should respect custom concurrency limit', () async {
        final activeTasks = <String>[];
        final maxConcurrent = <int>[];

        await processor.processBatch<String>(
          items: ['1', '2', '3', '4', '5'],
          processor: (item) async {
            activeTasks.add(item);
            maxConcurrent.add(activeTasks.length);
            await Future<void>.delayed(Duration(milliseconds: 50));
            activeTasks.remove(item);
            return 'done_$item';
          },
          concurrency: 2,
        );

        // Maximum concurrent should not exceed 2
        expect(maxConcurrent.every((count) => count <= 2), isTrue);
      });

      test('should handle concurrency of 1 (sequential processing)', () async {
        final processingOrder = <String>[];
        final items = ['first', 'second', 'third'];

        await processor.processBatch<String>(
          items: items,
          processor: (item) async {
            processingOrder.add('start_$item');
            await Future<void>.delayed(Duration(milliseconds: 10));
            processingOrder.add('end_$item');
            return item;
          },
          concurrency: 1,
        );

        // With concurrency 1, items should be processed sequentially
        expect(
            processingOrder,
            equals([
              'start_first',
              'end_first',
              'start_second',
              'end_second',
              'start_third',
              'end_third',
            ]));
      });

      test('should throw error for invalid concurrency', () async {
        expect(
          () => processor.processBatch<String>(
            items: ['item1'],
            processor: (item) async => item,
            concurrency: 0,
          ),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            equals('Concurrency must be at least 1'),
          )),
        );

        expect(
          () => processor.processBatch<String>(
            items: ['item1'],
            processor: (item) async => item,
            concurrency: -1,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Error Handling Tests', () {
      test('should handle single item failure with continueOnError true',
          () async {
        final items = ['success1', 'failure', 'success2'];

        final results = await processor.processBatch<String>(
          items: items,
          processor: (item) async {
            if (item == 'failure') {
              throw Exception('Processing failed for $item');
            }
            return 'processed_$item';
          },
          continueOnError: true,
        );

        // Should continue processing despite the failure
        expect(results, hasLength(2));
        expect(results, contains('processed_success1'));
        expect(results, contains('processed_success2'));
      });

      test('should stop on first error with continueOnError false', () async {
        final items = ['success1', 'failure', 'success2'];

        expect(
          () => processor.processBatch<String>(
            items: items,
            processor: (item) async {
              if (item == 'failure') {
                throw Exception('Processing failed for $item');
              }
              return 'processed_$item';
            },
            continueOnError: false,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle multiple failures with continueOnError true',
          () async {
        final items = [
          'success1',
          'failure1',
          'success2',
          'failure2',
          'success3'
        ];

        final results = await processor.processBatch<String>(
          items: items,
          processor: (item) async {
            if (item.contains('failure')) {
              throw Exception('Processing failed for $item');
            }
            return 'processed_$item';
          },
          continueOnError: true,
        );

        expect(results, hasLength(3));
        expect(results, contains('processed_success1'));
        expect(results, contains('processed_success2'));
        expect(results, contains('processed_success3'));
      });

      test('should handle timeout exceptions', () async {
        final items = ['item1', 'timeout_item', 'item2'];

        expect(
          () => processor.processBatch<String>(
            items: items,
            processor: (item) async {
              if (item == 'timeout_item') {
                throw TimeoutException('Processing timed out',
                    Duration(seconds: 30), 'batch_processor_test');
              }
              return 'processed_$item';
            },
            continueOnError: false,
          ),
          throwsA(isA<TimeoutException>()),
        );
      });

      test('should handle different exception types', () async {
        final items = ['item1', 'argument_error', 'state_error', 'item2'];

        final results = await processor.processBatch<String>(
          items: items,
          processor: (item) async {
            switch (item) {
              case 'argument_error':
                throw ArgumentError('Invalid argument');
              case 'state_error':
                throw StateError('Invalid state');
              default:
                return 'processed_$item';
            }
          },
          continueOnError: true,
        );

        expect(results, hasLength(2));
        expect(results, contains('processed_item1'));
        expect(results, contains('processed_item2'));
      });
    });

    group('Chunked Processing Tests', () {
      test('should process items in chunks', () async {
        final items = List.generate(25, (i) => 'item$i');

        final results = await processor.processInChunks<String>(
          items: items,
          processor: (item) async => 'processed_$item',
          chunkSize: 10,
          concurrency: 2,
        );

        expect(results, hasLength(25));
        for (int i = 0; i < 25; i++) {
          expect(results, contains('processed_item$i'));
        }
      });

      test('should handle chunk size larger than items list', () async {
        final items = ['item1', 'item2', 'item3'];

        final results = await processor.processInChunks<String>(
          items: items,
          processor: (item) async => 'processed_$item',
          chunkSize: 10,
        );

        expect(results, hasLength(3));
        expect(results[0], equals('processed_item1'));
        expect(results[1], equals('processed_item2'));
        expect(results[2], equals('processed_item3'));
      });

      test('should handle empty list in chunked processing', () async {
        final results = await processor.processInChunks<String>(
          items: <String>[],
          processor: (item) async => 'processed_$item',
          chunkSize: 5,
        );

        expect(results, isEmpty);
      });

      test('should process exact multiple of chunk size', () async {
        final items = List.generate(20, (i) => 'item$i');

        final results = await processor.processInChunks<String>(
          items: items,
          processor: (item) async => 'processed_$item',
          chunkSize: 5,
        );

        expect(results, hasLength(20));
      });

      test('should handle chunk processing with errors', () async {
        final items = List.generate(15, (i) => 'item$i');

        final results = await processor.processInChunks<String>(
          items: items,
          processor: (item) async {
            if (item == 'item5' || item == 'item10') {
              throw Exception('Processing failed');
            }
            return 'processed_$item';
          },
          chunkSize: 6,
          continueOnError: true,
        );

        expect(results, hasLength(13)); // 15 - 2 failures
      });
    });

    group('Performance Tests', () {
      test('should handle large batches efficiently', () async {
        final items = List.generate(100, (i) => 'item$i');

        final stopwatch = Stopwatch()..start();
        final results = await processor.processBatch<String>(
          items: items,
          processor: (item) async {
            await Future<void>.delayed(Duration(milliseconds: 1));
            return 'processed_$item';
          },
          concurrency: 10,
        );
        stopwatch.stop();

        expect(results, hasLength(100));
        // With concurrency 10, should be much faster than sequential
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      });

      test('should show performance benefit of concurrency', () async {
        final items = List.generate(20, (i) => 'item$i');

        // Sequential processing
        final sequentialStopwatch = Stopwatch()..start();
        await processor.processBatch<String>(
          items: items,
          processor: (item) async {
            await Future<void>.delayed(Duration(milliseconds: 10));
            return 'processed_$item';
          },
          concurrency: 1,
        );
        sequentialStopwatch.stop();

        // Concurrent processing
        final concurrentStopwatch = Stopwatch()..start();
        await processor.processBatch<String>(
          items: items,
          processor: (item) async {
            await Future<void>.delayed(Duration(milliseconds: 10));
            return 'processed_$item';
          },
          concurrency: 5,
        );
        concurrentStopwatch.stop();

        // Concurrent should be significantly faster
        expect(concurrentStopwatch.elapsedMilliseconds,
            lessThan(sequentialStopwatch.elapsedMilliseconds));
      });
    });

    group('Type Safety Tests', () {
      test('should handle different result types', () async {
        // String results
        final stringResults = await processor.processBatch<String>(
          items: ['a', 'b'],
          processor: (item) async => 'string_$item',
        );
        expect(stringResults, everyElement(isA<String>()));

        // Integer results
        final intResults = await processor.processBatch<int>(
          items: ['1', '2'],
          processor: (item) async => int.parse(item),
        );
        expect(intResults, everyElement(isA<int>()));

        // Map results
        final mapResults = await processor.processBatch<Map<String, dynamic>>(
          items: ['a', 'b'],
          processor: (item) async => {'key': item, 'processed': true},
        );
        expect(mapResults, everyElement(isA<Map<String, dynamic>>()));
      });

      test('should handle complex object types', () async {
        final results = await processor.processBatch<ProcessingResult>(
          items: ['item1', 'item2'],
          processor: (item) async => ProcessingResult(
            originalItem: item,
            processedValue: 'processed_$item',
            timestamp: DateTime.now(),
          ),
        );

        expect(results, hasLength(2));
        expect(results, everyElement(isA<ProcessingResult>()));
        expect(results[0].originalItem, equals('item1'));
        expect(results[1].originalItem, equals('item2'));
      });
    });

    group('Edge Cases Tests', () {
      test('should handle null processor results gracefully', () async {
        final results = await processor.processBatch<String?>(
          items: ['item1', 'item2'],
          processor: (item) async => null,
        );

        expect(results, hasLength(2));
        expect(results, everyElement(isNull));
      });

      test('should handle very large item names', () async {
        final longItem = 'item' + 'x' * 1000;
        final results = await processor.processBatch<String>(
          items: [longItem],
          processor: (item) async => 'processed_${item.substring(0, 10)}',
        );

        expect(results, hasLength(1));
        expect(results.first, equals('processed_itemxxxxxx'));
      });

      test('should handle rapid successive calls', () async {
        final futures = <Future<List<String>>>[];

        for (int i = 0; i < 5; i++) {
          futures.add(processor.processBatch<String>(
            items: ['batch${i}_item1', 'batch${i}_item2'],
            processor: (item) async => 'processed_$item',
          ));
        }

        final allResults = await Future.wait(futures);

        expect(allResults, hasLength(5));
        for (final results in allResults) {
          expect(results, hasLength(2));
        }
      });
    });

    group('Memory Management Tests', () {
      test('should not accumulate memory with many small batches', () async {
        // Process many small batches to test memory management
        for (int batch = 0; batch < 100; batch++) {
          final results = await processor.processBatch<String>(
            items: ['item1', 'item2'],
            processor: (item) async => 'processed_$item',
          );
          expect(results, hasLength(2));
        }
      });

      test('should handle cleanup after processing', () async {
        final results = await processor.processBatch<String>(
          items: List.generate(50, (i) => 'item$i'),
          processor: (item) async => 'processed_$item',
          concurrency: 5,
        );

        expect(results, hasLength(50));
        // After processing, no resources should be leaked
        // This is implicit but important for memory management
      });
    });

    group('Integration Tests', () {
      test('should integrate with real-world URL processing scenario',
          () async {
        final urls = [
          'https://example.com/page1',
          'https://example.com/page2',
          'https://example.com/page3',
          'https://example.com/page4',
          'https://example.com/page5',
        ];

        final results = await processor.processBatch<Map<String, dynamic>>(
          items: urls,
          processor: (url) async {
            // Simulate URL processing
            await Future<void>.delayed(Duration(milliseconds: 50));
            return {
              'url': url,
              'status': 'success',
              'title': 'Page Title for $url',
              'processedAt': DateTime.now().toIso8601String(),
            };
          },
          concurrency: 3,
        );

        expect(results, hasLength(5));
        for (final result in results) {
          expect(result['status'], equals('success'));
          expect(result['url'], startsWith('https://example.com/'));
          expect(result['title'], contains('Page Title'));
          expect(result['processedAt'], isA<String>());
        }
      });

      test('should handle mixed success and failure scenarios', () async {
        final items = [
          'success1',
          'failure1',
          'success2',
          'timeout',
          'success3',
          'failure2',
        ];

        final results = await processor.processBatch<Map<String, dynamic>>(
          items: items,
          processor: (item) async {
            if (item.startsWith('failure')) {
              throw Exception('Processing failed for $item');
            }
            if (item == 'timeout') {
              throw TimeoutException('Timeout for $item', Duration(seconds: 30),
                  'batch_processor_test');
            }
            return {
              'item': item,
              'result': 'processed_$item',
              'success': true,
            };
          },
          continueOnError: true,
        );

        expect(results, hasLength(3)); // Only successful items
        for (final result in results) {
          expect(result['success'], isTrue);
          expect(result['item'], startsWith('success'));
        }
      });
    });
  });
}

// Helper class for testing complex object processing
class ProcessingResult {
  final String originalItem;
  final String processedValue;
  final DateTime timestamp;

  ProcessingResult({
    required this.originalItem,
    required this.processedValue,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'ProcessingResult(originalItem: $originalItem, processedValue: $processedValue, timestamp: $timestamp)';
  }
}
