import 'package:ai_webscraper/src/core/ai_model.dart';
import 'package:ai_webscraper/src/core/ai_provider.dart';
import 'package:ai_webscraper/src/core/ai_webscraper.dart';
import 'package:test/test.dart';

void main() {
  group('AIWebScraper', () {
    test('should create instance with valid OpenAI API key', () {
      final scraper = AIWebScraper(
        aiModel: AIModel.gpt4o,
        apiKey: 'sk-test-key-123',
      );

      expect(scraper.aiModel, equals(AIModel.gpt4o));
      expect(scraper.aiModel.provider, equals(AIProvider.openai));
      expect(scraper.apiKey, equals('sk-test-key-123'));
      expect(scraper.timeout, equals(const Duration(seconds: 30)));
      expect(scraper.useJavaScript, isFalse);
    });

    test('should create instance with valid Gemini API key', () {
      final scraper = AIWebScraper(
        aiModel: AIModel.gemini25Pro,
        apiKey: 'AItest-key-123',
      );

      expect(scraper.aiModel, equals(AIModel.gemini25Pro));
      expect(scraper.aiModel.provider, equals(AIProvider.gemini));
      expect(scraper.apiKey, equals('AItest-key-123'));
    });

    test('should create instance with custom timeout', () {
      final scraper = AIWebScraper(
        aiModel: AIModel.gpt4o,
        apiKey: 'sk-test-key-123',
        timeout: const Duration(seconds: 60),
      );

      expect(scraper.timeout, equals(const Duration(seconds: 60)));
    });

    test('should create instance with JavaScript scraping enabled', () {
      final scraper = AIWebScraper(
        aiModel: AIModel.gpt4o,
        apiKey: 'sk-test-key-123',
        useJavaScript: true,
      );

      expect(scraper.useJavaScript, isTrue);
    });

    test('should throw error with empty API key', () {
      expect(
        () => AIWebScraper(
          aiModel: AIModel.gpt4o,
          apiKey: '',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should throw error with whitespace-only API key', () {
      expect(
        () => AIWebScraper(
          aiModel: AIModel.gpt4o,
          apiKey: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should validate API key format', () {
      final scraper = AIWebScraper(
        aiModel: AIModel.gpt4o,
        apiKey:
            'sk-test-key-123456789012345678901234567890', // 38 chars total, 20+ after 'sk-'
      );

      expect(scraper.validateApiKey(), isTrue);
    });

    test('should provide provider info', () {
      final scraper = AIWebScraper(
        aiModel: AIModel.gpt4o,
        apiKey: 'sk-test-key-123',
      );

      expect(scraper.providerInfo, equals('OpenAI'));
    });

    test('should provide max content length', () {
      final scraper = AIWebScraper(
        aiModel: AIModel.gpt4o,
        apiKey: 'sk-test-key-123',
      );

      expect(scraper.maxContentLength, isNotNull);
      expect(scraper.maxContentLength, greaterThan(0));
    });

    test('should handle disposal without errors', () {
      final scraper = AIWebScraper(
        aiModel: AIModel.gpt4o,
        apiKey: 'sk-test-key-123',
      );

      expect(() => scraper.dispose(), returnsNormally);
    });
  });
}
