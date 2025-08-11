import 'dart:async';
import 'dart:collection';

/// Utility class for processing items in batches with concurrency control.
///
/// This class provides functionality to process multiple items concurrently
/// while respecting concurrency limits and handling errors appropriately.
class BatchProcessor {
  /// Processes a batch of items with controlled concurrency.
  ///
  /// [items] - List of items to process
  /// [processor] - Function that processes each item
  /// [concurrency] - Maximum number of concurrent operations
  /// [continueOnError] - Whether to continue processing if individual items fail
  ///
  /// Returns a list of results from processing each item.
  Future<List<T>> processBatch<T>({
    required List<String> items,
    required Future<T> Function(String item) processor,
    int concurrency = 3,
    bool continueOnError = true,
  }) async {
    if (items.isEmpty) {
      return <T>[];
    }

    if (concurrency < 1) {
      throw ArgumentError('Concurrency must be at least 1');
    }

    final List<T> results = <T>[];
    final Semaphore semaphore = Semaphore(concurrency);

    // Create a wrapper to distinguish between successful null results and failures
    final Iterable<Future<_ProcessingResult<T>>> futures = items.map((String item) async {
      await semaphore.acquire();

      try {
        final T result = await processor(item);
        return _ProcessingResult<T>.success(result);
      } catch (e) {
        if (!continueOnError) {
          rethrow;
        }
        // When continuing on error, return a failure result
        return _ProcessingResult<T>.failure(e);
      } finally {
        semaphore.release();
      }
    });

    try {
      final List<_ProcessingResult<T>> completedResults = await Future.wait(
        futures,
        eagerError: !continueOnError,
      );

      // Collect only successful results
      for (final _ProcessingResult<T> result in completedResults) {
        if (result.isSuccess) {
          results.add(result.value);
        }
      }
    } catch (e) {
      // When continueOnError is false, propagate the original exception
      rethrow;
    }

    return results;
  }

  /// Processes items in chunks to reduce memory usage.
  ///
  /// [items] - List of items to process
  /// [processor] - Function that processes each item
  /// [chunkSize] - Size of each chunk to process
  /// [concurrency] - Maximum number of concurrent operations per chunk
  /// [continueOnError] - Whether to continue processing if individual items fail
  ///
  /// Returns a list of results from processing all items.
  Future<List<T>> processInChunks<T>({
    required List<String> items,
    required Future<T> Function(String item) processor,
    int chunkSize = 10,
    int concurrency = 3,
    bool continueOnError = true,
  }) async {
    final List<T> allResults = <T>[];

    for (int i = 0; i < items.length; i += chunkSize) {
      final int end = (i + chunkSize < items.length) ? i + chunkSize : items.length;
      final List<String> chunk = items.sublist(i, end);

      final List<T> chunkResults = await processBatch<T>(
        items: chunk,
        processor: processor,
        concurrency: concurrency,
        continueOnError: continueOnError,
      );

      allResults.addAll(chunkResults);
    }

    return allResults;
  }

  /// Processes items with retry logic.
  ///
  /// [items] - List of items to process
  /// [processor] - Function that processes each item
  /// [concurrency] - Maximum number of concurrent operations
  /// [maxRetries] - Maximum number of retry attempts per item
  /// [retryDelay] - Delay between retry attempts
  /// [continueOnError] - Whether to continue processing if individual items fail
  ///
  /// Returns a list of results from processing each item.
  Future<List<T>> processBatchWithRetry<T>({
    required List<String> items,
    required Future<T> Function(String item) processor,
    int concurrency = 3,
    int maxRetries = 2,
    Duration retryDelay = const Duration(seconds: 1),
    bool continueOnError = true,
  }) async {
    Future<T> retryableProcessor(String item) async {
      Object? lastError;

      for (int attempt = 0; attempt <= maxRetries; attempt++) {
        try {
          return await processor(item);
        } on FormatException catch (e) {
          lastError = e;
          if (attempt < maxRetries) {
            await Future<void>.delayed(retryDelay);
          }
        }
      }

      // ignore: only_throw_errors
      throw lastError!;
    }

    return processBatch<T>(
      items: items,
      processor: retryableProcessor,
      concurrency: concurrency,
      continueOnError: continueOnError,
    );
  }
}

/// A semaphore implementation for controlling concurrency.
class Semaphore {

  /// Creates a semaphore with the specified maximum count.
  Semaphore(this._maxCount) : _currentCount = _maxCount;
  final int _maxCount;
  int _currentCount;
  final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();

  /// Acquires a permit from the semaphore.
  ///
  /// If no permits are available, this method will wait until one becomes available.
  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }

    final Completer<void> completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  /// Releases a permit back to the semaphore.
  ///
  /// This allows waiting operations to proceed.
  void release() {
    if (_waitQueue.isNotEmpty) {
      _waitQueue.removeFirst()
      .complete();
    } else {
      _currentCount++;
      // Ensure we don't exceed the maximum count
      if (_currentCount > _maxCount) {
        _currentCount = _maxCount;
      }
    }
  }

  /// Gets the current number of available permits.
  int get availablePermits => _currentCount;

  /// Gets the number of operations waiting for permits.
  int get queueLength => _waitQueue.length;
}

/// Internal helper class to distinguish between successful results and failures.
class _ProcessingResult<T> {

  _ProcessingResult.failure(this._error)
      : _value = null,
        isSuccess = false;

  _ProcessingResult.success(this._value)
      : _error = null,
        isSuccess = true;
  final T? _value;
  final Object? _error;
  final bool isSuccess;

  T get value {
    if (!isSuccess) {
      throw StateError('Cannot get value from failed result');
    }
    return _value as T;
  }

  Object? get error {
    if (isSuccess) {
      throw StateError('Cannot get error from successful result');
    }
    return _error;
  }
}
