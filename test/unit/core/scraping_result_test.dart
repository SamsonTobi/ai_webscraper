import 'dart:convert';

import 'package:test/test.dart';
import 'package:ai_webscraper/ai_webscraper.dart';

void main() {
  group('ScrapingResult', () {
    const testUrl = 'https://example.com';
    const testData = {'title': 'Test Title', 'price': 19.99};
    const testError = 'Test error message';
    final testDuration = Duration(seconds: 2);
    const testProvider = AIProvider.openai;

    group('Constructor Tests', () {
      test('should create successful result with required parameters', () {
        final result = ScrapingResult(
          success: true,
          data: testData,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        expect(result.success, isTrue);
        expect(result.data, equals(testData));
        expect(result.error, isNull);
        expect(result.scrapingTime, equals(testDuration));
        expect(result.aiProvider, equals(testProvider));
        expect(result.url, equals(testUrl));
        expect(result.timestamp, isA<DateTime>());
      });

      test('should create failed result with required parameters', () {
        final result = ScrapingResult(
          success: false,
          error: testError,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        expect(result.success, isFalse);
        expect(result.data, isNull);
        expect(result.error, equals(testError));
        expect(result.scrapingTime, equals(testDuration));
        expect(result.aiProvider, equals(testProvider));
        expect(result.url, equals(testUrl));
        expect(result.timestamp, isA<DateTime>());
      });

      test('should use provided timestamp', () {
        final customTimestamp = DateTime(2023, 1, 1, 12, 0, 0);
        final result = ScrapingResult(
          success: true,
          data: testData,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
          timestamp: customTimestamp,
        );

        expect(result.timestamp, equals(customTimestamp));
      });
    });

    group('Factory Constructor Tests', () {
      test('should create successful result using success factory', () {
        final result = ScrapingResult.success(
          data: testData,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        expect(result.success, isTrue);
        expect(result.data, equals(testData));
        expect(result.error, isNull);
        expect(result.scrapingTime, equals(testDuration));
        expect(result.aiProvider, equals(testProvider));
        expect(result.url, equals(testUrl));
      });

      test('should create failed result using failure factory', () {
        final result = ScrapingResult.failure(
          error: testError,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        expect(result.success, isFalse);
        expect(result.data, isNull);
        expect(result.error, equals(testError));
        expect(result.scrapingTime, equals(testDuration));
        expect(result.aiProvider, equals(testProvider));
        expect(result.url, equals(testUrl));
      });

      test('should use custom timestamp in factory constructors', () {
        final customTimestamp = DateTime(2023, 1, 1, 12, 0, 0);
        final result = ScrapingResult.success(
          data: testData,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
          timestamp: customTimestamp,
        );

        expect(result.timestamp, equals(customTimestamp));
      });
    });

    group('Property Tests', () {
      test('hasData should return true for successful result with data', () {
        final result = ScrapingResult.success(
          data: testData,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        expect(result.hasData, isTrue);
      });

      test('hasData should return false for successful result with empty data',
          () {
        final result = ScrapingResult.success(
          data: <String, dynamic>{},
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        expect(result.hasData, isFalse);
      });

      test('hasData should return false for failed result', () {
        final result = ScrapingResult.failure(
          error: testError,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        expect(result.hasData, isFalse);
      });

      test('hasError should return true for failed result with error', () {
        final result = ScrapingResult.failure(
          error: testError,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        expect(result.hasError, isTrue);
      });

      test('hasError should return false for successful result', () {
        final result = ScrapingResult.success(
          data: testData,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        expect(result.hasError, isFalse);
      });

      test('fieldCount should return correct number of fields', () {
        final result = ScrapingResult.success(
          data: testData,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        expect(result.fieldCount, equals(2));
      });

      test('fieldCount should return 0 for failed result', () {
        final result = ScrapingResult.failure(
          error: testError,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        expect(result.fieldCount, equals(0));
      });

      test('fieldNames should return correct field names', () {
        final result = ScrapingResult.success(
          data: testData,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        expect(result.fieldNames, containsAll(['title', 'price']));
        expect(result.fieldNames.length, equals(2));
      });

      test('fieldNames should return empty list for failed result', () {
        final result = ScrapingResult.failure(
          error: testError,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        expect(result.fieldNames, isEmpty);
      });
    });

    group('getField Tests', () {
      test('should return field value with correct type', () {
        final result = ScrapingResult.success(
          data: testData,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        expect(result.getField<String>('title'), equals('Test Title'));
        expect(result.getField<double>('price'), equals(19.99));
      });

      test('should return null for non-existent field', () {
        final result = ScrapingResult.success(
          data: testData,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        expect(result.getField<String>('nonexistent'), isNull);
      });

      test('should return null for wrong type', () {
        final result = ScrapingResult.success(
          data: testData,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        expect(result.getField<int>('title'), isNull);
      });

      test('should return null for failed result', () {
        final result = ScrapingResult.failure(
          error: testError,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        expect(result.getField<String>('title'), isNull);
      });
    });

    group('copyWith Tests', () {
      test('should create copy with updated success status', () {
        final original = ScrapingResult.success(
          data: testData,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        final copy = original.copyWith(success: false, error: testError);

        expect(copy.success, isFalse);
        expect(copy.error, equals(testError));
        expect(copy.data, equals(testData)); // Original data preserved
        expect(copy.scrapingTime, equals(testDuration));
        expect(copy.aiProvider, equals(testProvider));
        expect(copy.url, equals(testUrl));
      });

      test('should create copy with updated data', () {
        final original = ScrapingResult.success(
          data: testData,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        final newData = {
          'title': 'New Title',
          'description': 'New Description'
        };
        final copy = original.copyWith(data: newData);

        expect(copy.data, equals(newData));
        expect(copy.success, isTrue); // Original success preserved
        expect(copy.scrapingTime, equals(testDuration));
        expect(copy.aiProvider, equals(testProvider));
        expect(copy.url, equals(testUrl));
      });

      test('should preserve unchanged values in copy', () {
        final original = ScrapingResult.success(
          data: testData,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        final copy = original.copyWith();

        expect(copy.success, equals(original.success));
        expect(copy.data, equals(original.data));
        expect(copy.error, equals(original.error));
        expect(copy.scrapingTime, equals(original.scrapingTime));
        expect(copy.aiProvider, equals(original.aiProvider));
        expect(copy.url, equals(original.url));
        expect(copy.timestamp, equals(original.timestamp));
      });
    });

    group('JSON Serialization Tests', () {
      test('should serialize successful result to JSON', () {
        final result = ScrapingResult.success(
          data: testData,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        final json = result.toJson();

        expect(json['success'], isTrue);
        expect(json['data'], equals(testData));
        expect(json['error'], isNull);
        expect(json['scrapingTimeMs'], equals(testDuration.inMilliseconds));
        expect(json['aiProvider'], equals(testProvider.name));
        expect(json['url'], equals(testUrl));
        expect(json['timestamp'], isA<String>());
        expect(json['fieldCount'], equals(2));
      });

      test('should serialize failed result to JSON', () {
        final result = ScrapingResult.failure(
          error: testError,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        final json = result.toJson();

        expect(json['success'], isFalse);
        expect(json['data'], isNull);
        expect(json['error'], equals(testError));
        expect(json['scrapingTimeMs'], equals(testDuration.inMilliseconds));
        expect(json['aiProvider'], equals(testProvider.name));
        expect(json['url'], equals(testUrl));
        expect(json['fieldCount'], equals(0));
      });

      test('should deserialize successful result from JSON', () {
        final originalResult = ScrapingResult.success(
          data: testData,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        final json = originalResult.toJson();
        final deserializedResult = ScrapingResult.fromJson(json);

        expect(deserializedResult.success, equals(originalResult.success));
        expect(deserializedResult.data, equals(originalResult.data));
        expect(deserializedResult.error, equals(originalResult.error));
        expect(deserializedResult.scrapingTime,
            equals(originalResult.scrapingTime));
        expect(
            deserializedResult.aiProvider, equals(originalResult.aiProvider));
        expect(deserializedResult.url, equals(originalResult.url));
        expect(deserializedResult.timestamp, equals(originalResult.timestamp));
      });

      test('should deserialize failed result from JSON', () {
        final originalResult = ScrapingResult.failure(
          error: testError,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        final json = originalResult.toJson();
        final deserializedResult = ScrapingResult.fromJson(json);

        expect(deserializedResult.success, equals(originalResult.success));
        expect(deserializedResult.data, equals(originalResult.data));
        expect(deserializedResult.error, equals(originalResult.error));
        expect(deserializedResult.scrapingTime,
            equals(originalResult.scrapingTime));
        expect(
            deserializedResult.aiProvider, equals(originalResult.aiProvider));
        expect(deserializedResult.url, equals(originalResult.url));
        expect(deserializedResult.timestamp, equals(originalResult.timestamp));
      });
    });

    group('toString Tests', () {
      test('should return JSON string for successful result', () {
        final result = ScrapingResult.success(
          data: testData,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        final stringResult = result.toString();

        // Should be valid JSON
        expect(() => jsonDecode(stringResult), returnsNormally);

        final json = jsonDecode(stringResult) as Map<String, dynamic>;
        expect(json['success'], isTrue);
        expect(json['data'], equals(testData));
        expect(json['metadata']['url'], equals(testUrl));
        expect(json['metadata']['aiProvider'], equals('OpenAI'));
        expect(json['metadata']['fieldCount'], equals(2));
      });

      test('should return JSON string for failed result', () {
        final result = ScrapingResult.failure(
          error: testError,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        final stringResult = result.toString();

        // Should be valid JSON
        expect(() => jsonDecode(stringResult), returnsNormally);

        final json = jsonDecode(stringResult) as Map<String, dynamic>;
        expect(json['success'], isFalse);
        expect(json['error'], equals(testError));
        expect(json['metadata']['url'], equals(testUrl));
        expect(json['metadata']['aiProvider'], equals('OpenAI'));
      });
    });

    group('Equality Tests', () {
      test('should be equal when all fields match', () {
        final timestamp = DateTime.now();
        final result1 = ScrapingResult(
          success: true,
          data: testData,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
          timestamp: timestamp,
        );

        final result2 = ScrapingResult(
          success: true,
          data: testData,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
          timestamp: timestamp,
        );

        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('should not be equal when success differs', () {
        final result1 = ScrapingResult.success(
          data: testData,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        final result2 = ScrapingResult.failure(
          error: testError,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        expect(result1, isNot(equals(result2)));
      });

      test('should not be equal when data differs', () {
        final result1 = ScrapingResult.success(
          data: testData,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        final result2 = ScrapingResult.success(
          data: {'title': 'Different Title'},
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        expect(result1, isNot(equals(result2)));
      });

      test('should be equal to itself', () {
        final result = ScrapingResult.success(
          data: testData,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        expect(result, equals(result));
      });

      test('should not be equal to different type', () {
        final result = ScrapingResult.success(
          data: testData,
          scrapingTime: testDuration,
          aiProvider: testProvider,
          url: testUrl,
        );

        expect(result, isNot(equals('not a scraping result')));
      });
    });
  });
}
