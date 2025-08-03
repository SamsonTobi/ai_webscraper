import 'package:ai_webscraper/src/ai/ai_client_base.dart';
import 'package:ai_webscraper/src/ai/ai_client_factory.dart';
import 'package:ai_webscraper/src/ai/gemini_client.dart';
import 'package:ai_webscraper/src/ai/openai_client.dart';
import 'package:ai_webscraper/src/core/ai_model.dart';
import 'package:ai_webscraper/src/core/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('AIClientFactory', () {
    group('create', () {
      test('should create OpenAI client with valid API key', () {
        final AIClientBase client = AIClientFactory.create(
          AIModel.gpt4o,
          'sk-test-key-123',
        );

        expect(client, isA<OpenAIClient>());
        expect(client.providerName, equals('OpenAI'));
        expect(client.apiKey, equals('sk-test-key-123'));
      });

      test('should create Gemini client with valid API key', () {
        final AIClientBase client = AIClientFactory.create(
          AIModel.gemini25Pro,
          'AItest-key-123',
        );

        expect(client, isA<GeminiClient>());
        expect(client.providerName, equals('Gemini'));
        expect(client.apiKey, equals('AItest-key-123'));
      });

      test('should create client with custom timeout', () {
        const Duration customTimeout = Duration(seconds: 60);
        final AIClientBase client = AIClientFactory.create(
          AIModel.gpt35Turbo,
          'sk-test-key-123',
          timeout: customTimeout,
        );

        expect(client.timeout, equals(customTimeout));
      });

      test('should create client with custom options', () {
        final Map<String, Object> options = <String, Object>{
          'temperature': 0.5
        };
        final OpenAIClient client = AIClientFactory.create(
          AIModel.gpt4,
          'sk-test-key-123',
          options: options,
        ) as OpenAIClient;

        expect(client.options, equals(options));
      });

      test('should create client with default timeout when not specified', () {
        final AIClientBase client = AIClientFactory.create(
          AIModel.gpt35Turbo,
          'sk-test-key-123',
        );

        expect(client.timeout, equals(const Duration(seconds: 30)));
      });

      test('should handle null options', () {
        final OpenAIClient client = AIClientFactory.create(
          AIModel.gpt4,
          'sk-test-key-123',
          options: null,
        ) as OpenAIClient;

        expect(client.options, isNull);
      });

      test('should throw ArgumentError for empty API key', () {
        expect(
          () => AIClientFactory.create(AIModel.gpt4o, ''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should create multiple clients independently', () {
        final AIClientBase client1 = AIClientFactory.create(
          AIModel.gpt4o,
          'sk-key-1',
        );
        final AIClientBase client2 = AIClientFactory.create(
          AIModel.gemini25Pro,
          'AI-key-2',
        );

        expect(client1.apiKey, equals('sk-key-1'));
        expect(client2.apiKey, equals('AI-key-2'));
        expect(identical(client1, client2), isFalse);
      });
    });

    group('createWithValidation', () {
      test('should create OpenAI client with valid API key format', () {
        expect(
          () => AIClientFactory.createWithValidation(
            AIModel.gpt4o,
            'sk-test-key-123456789012345678901234567890', // At least 20 chars
          ),
          returnsNormally,
        );
      });

      test('should create Gemini client with valid API key format', () {
        expect(
          () => AIClientFactory.createWithValidation(
            AIModel.gemini25Pro,
            'AIzaSyTest-key-123456789012345678901234567890', // At least 20 chars starting with AI
          ),
          returnsNormally,
        );
      });

      test('should throw InvalidApiKeyException for invalid OpenAI key', () {
        expect(
          () => AIClientFactory.createWithValidation(
            AIModel.gpt35Turbo,
            'invalid-key',
          ),
          throwsA(isA<InvalidApiKeyException>()),
        );
      });

      test('should throw ArgumentError for empty API key before validation',
          () {
        expect(
          () => AIClientFactory.createWithValidation(AIModel.gpt4o, ''),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('AI Model specific tests', () {
      test('should use correct model name for GPT-4o', () {
        final AIClientBase client = AIClientFactory.create(
          AIModel.gpt4o,
          'sk-test-key',
        );

        expect((client as OpenAIClient).model, equals(AIModel.gpt4o.modelName));
      });

      test('should use correct model name for Gemini 1.5 Pro', () {
        final AIClientBase client = AIClientFactory.create(
          AIModel.gemini25Pro,
          'AI-test-key',
        );

        expect((client as GeminiClient).model,
            equals(AIModel.gemini25Pro.modelName));
      });

      test('should create different models for same provider', () {
        final AIClientBase gpt4Client = AIClientFactory.create(
          AIModel.gpt4,
          'sk-test-key',
        );
        final AIClientBase gpt35Client = AIClientFactory.create(
          AIModel.gpt35Turbo,
          'sk-test-key',
        );

        expect((gpt4Client as OpenAIClient).model, equals('gpt-4'));
        expect((gpt35Client as OpenAIClient).model, equals('gpt-3.5-turbo'));
      });
    });

    group('edge cases', () {
      test('should handle very long API keys', () {
        final String longApiKey = 'sk-${'a' * 100}';

        expect(
          () => AIClientFactory.create(AIModel.gpt4o, longApiKey),
          returnsNormally,
        );
      });

      test('should handle API keys with special characters', () {
        const String specialKey = 'sk-test_key-123.456';

        expect(
          () => AIClientFactory.create(AIModel.gpt35Turbo, specialKey),
          returnsNormally,
        );
      });

      test('should handle zero timeout', () {
        final AIClientBase client = AIClientFactory.create(
          AIModel.gpt4o,
          'sk-test-key',
          timeout: Duration.zero,
        );

        expect(client.timeout, equals(Duration.zero));
      });
    });
  });
}
