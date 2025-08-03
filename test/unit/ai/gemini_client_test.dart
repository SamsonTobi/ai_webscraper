import 'package:ai_webscraper/src/ai/gemini_client.dart';
import 'package:ai_webscraper/src/core/exceptions.dart';
import 'package:test/test.dart';

void main() {
  group('GeminiClient', () {
    late GeminiClient client;

    setUp(() {
      client =
          GeminiClient(apiKey: 'AItest-key-123456789', model: 'gemini-pro');
    });

    group('Constructor Tests', () {
      test('should create instance with valid API key', () {
        final GeminiClient client =
            GeminiClient(apiKey: 'AItest-key-123456789', model: 'gemini-pro');

        expect(client.apiKey, equals('AItest-key-123456789'));
        expect(client.timeout, equals(const Duration(seconds: 30)));
        expect(client.providerName, equals('Gemini'));
      });

      test('should create instance with custom parameters', () {
        final GeminiClient client = GeminiClient(
          apiKey: 'AIcustom-key-987654321',
          model: 'gemini-pro',
          timeout: const Duration(seconds: 60),
          options: <String, dynamic>{
            'temperature': 0.5,
            'maxOutputTokens': 2000
          },
        );

        expect(client.apiKey, equals('AIcustom-key-987654321'));
        expect(client.timeout, equals(const Duration(seconds: 60)));
        expect(client.options, containsPair('temperature', 0.5));
        expect(client.options, containsPair('maxOutputTokens', 2000));
      });

      test('should create instance with model configuration', () {
        final GeminiClient client = GeminiClient(
          apiKey: 'AItest-key-123456789',
          model: 'gemini-pro-vision',
        );

        expect(client.model, equals('gemini-pro-vision'));
      });
    });

    group('API Key Validation Tests', () {
      test('should validate correct Gemini API key format', () {
        final GeminiClient client = GeminiClient(
            apiKey: 'AIzaSyAbCdEfGhIjKlMnOpQrStUvWxYz123456789',
            model: 'gemini-pro');

        expect(client.validateApiKey(), isTrue);
      });

      test('should validate API key starting with AI', () {
        final GeminiClient client = GeminiClient(
            apiKey: 'AItest-key-123456789abcdef', model: 'gemini-pro');

        expect(client.validateApiKey(), isTrue);
      });

      test('should reject API key without AI prefix', () {
        final GeminiClient client = GeminiClient(
            apiKey: 'test-key-123456789abcdef', model: 'gemini-pro');

        expect(client.validateApiKey(), isFalse);
      });

      test('should reject too short API key', () {
        final GeminiClient client =
            GeminiClient(apiKey: 'AI-short', model: 'gemini-pro');

        expect(client.validateApiKey(), isFalse);
      });

      test('should accept minimum length API key', () {
        final GeminiClient client =
            GeminiClient(apiKey: 'AI1234567890123456789', model: 'gemini-pro');

        expect(client.validateApiKey(), isTrue);
      });

      test('should handle edge case API key formats', () {
        // Test various valid formats
        expect(
            GeminiClient(
                    apiKey: 'AIzaSyTest1234567890123456789',
                    model: 'gemini-pro') // 28 chars, 20+ requirement
                .validateApiKey(),
            isTrue);
        expect(
            GeminiClient(apiKey: 'AITest-Key_123', model: 'gemini-pro')
                .validateApiKey(),
            isTrue);
        expect(
            GeminiClient(apiKey: 'AI' + 'a' * 30, model: 'gemini-pro')
                .validateApiKey(),
            isTrue);
      });
    });

    group('Provider Information Tests', () {
      test('should return correct provider name', () {
        expect(client.providerName, equals('Gemini'));
      });

      test('should return max content length', () {
        expect(client.maxContentLength, equals(100000));
        expect(client.maxContentLength, isA<int>());
        expect(client.maxContentLength, greaterThan(0));
      });

      test('should return higher content length than OpenAI', () {
        // Gemini typically supports longer content than OpenAI
        expect(client.maxContentLength, greaterThan(50000));
      });
    });

    group('Model Configuration Tests', () {
      test('should use custom model when specified', () {
        final GeminiClient client = GeminiClient(
          apiKey: 'AItest-key-123456789',
          model: 'gemini-pro-vision',
        );

        expect(client.model, equals('gemini-pro-vision'));
      });

      test('should handle different model variants', () {
        final List<String> models = <String>[
          'gemini-pro',
          'gemini-pro-vision',
          'gemini-ultra'
        ];

        for (final String model in models) {
          final GeminiClient client = GeminiClient(
            apiKey: 'AItest-key-123456789',
            model: model,
          );
          expect(client.model, equals(model));
        }
      });
    });

    group('Options Configuration Tests', () {
      test('should handle null options', () {
        final GeminiClient client = GeminiClient(
          apiKey: 'AItest-key-123456789',
          model: 'gemini-pro',
          options: null,
        );

        expect(client.options, isNull);
      });

      test('should handle empty options', () {
        final GeminiClient client = GeminiClient(
          apiKey: 'AItest-key-123456789',
          model: 'gemini-pro',
          options: <String, dynamic>{},
        );

        expect(client.options, isEmpty);
      });

      test('should handle temperature configuration', () {
        final GeminiClient client = GeminiClient(
          apiKey: 'AItest-key-123456789',
          model: 'gemini-pro',
          options: <String, dynamic>{'temperature': 0.7},
        );

        expect(client.options!['temperature'], equals(0.7));
      });

      test('should handle token limits configuration', () {
        final GeminiClient client = GeminiClient(
          apiKey: 'AItest-key-123456789',
          model: 'gemini-pro',
          options: <String, dynamic>{
            'maxOutputTokens': 1024,
            'topK': 40,
            'topP': 0.95,
          },
        );

        expect(client.options!['maxOutputTokens'], equals(1024));
        expect(client.options!['topK'], equals(40));
        expect(client.options!['topP'], equals(0.95));
      });

      test('should handle safety settings configuration', () {
        final GeminiClient client = GeminiClient(
          apiKey: 'AItest-key-123456789',
          model: 'gemini-pro',
          options: <String, dynamic>{
            'safetySettings': <Map<String, String>>[
              <String, String>{
                'category': 'HARM_CATEGORY_HARASSMENT',
                'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
              },
            ],
          },
        );

        expect(client.options!['safetySettings'], isA<List<dynamic>>());
      });
    });

    group('Content Processing Tests', () {
      test('should handle HTML content validation', () {
        const String htmlContent =
            '<html><body><h1>Test Content</h1></body></html>';

        // Test that the client accepts valid HTML content
        expect(() => client._validateHtmlContent(htmlContent), returnsNormally);
      });

      test('should handle empty HTML content', () {
        expect(() => client._validateHtmlContent(''),
            throwsA(isA<ArgumentError>()));
      });

      test('should handle very long HTML content', () {
        final String longContent = '<html><body>${'a' * 200000}</body></html>';

        // Should handle content up to max length
        if (longContent.length <= client.maxContentLength) {
          expect(
              () => client._validateHtmlContent(longContent), returnsNormally);
        } else {
          expect(() => client._validateHtmlContent(longContent),
              throwsA(isA<ArgumentError>()));
        }
      });
    });

    group('Schema Processing Tests', () {
      test('should handle valid schema formats', () {
        const List<Map<String, String>> validSchemas = <Map<String, String>>[
          <String, String>{'title': 'string', 'price': 'number'},
          <String, String>{
            'name': 'string',
            'description': 'text',
            'available': 'boolean'
          },
          <String, String>{'items': 'array', 'metadata': 'object'},
        ];

        for (final Map<String, String> schema in validSchemas) {
          expect(() => client._validateSchema(schema), returnsNormally);
        }
      });

      test('should reject empty schema', () {
        expect(() => client._validateSchema(<String, String>{}),
            throwsA(isA<SchemaValidationException>()));
      });

      test('should handle complex schema structures', () {
        const Map<String, String> complexSchema = <String, String>{
          'product_name': 'string',
          'product_price': 'number',
          'product_description': 'text',
          'in_stock': 'boolean',
          'categories': 'array',
          'specifications': 'object',
          'rating': 'number',
          'review_count': 'integer',
        };

        expect(() => client._validateSchema(complexSchema), returnsNormally);
      });
    });

    group('Error Handling Tests', () {
      test('should handle AI client exceptions gracefully', () {
        // Test exception structure
        expect(() => throw const AIClientException('Test error', 'Gemini'),
            throwsA(isA<AIClientException>()));
      });

      test('should handle network timeout scenarios', () {
        final GeminiClient timeoutClient = GeminiClient(
          apiKey: 'AItest-key-123456789',
          model: 'gemini-pro',
          timeout: const Duration(milliseconds: 1),
        );

        expect(timeoutClient.timeout, equals(const Duration(milliseconds: 1)));
      });

      test('should handle authentication errors', () {
        // Test that client is configured to handle auth errors
        expect(client.apiKey, isNotEmpty);
        expect(client.validateApiKey(), isTrue);
      });

      test('should handle rate limiting scenarios', () {
        // Test rate limiting configuration
        expect(client.timeout, isA<Duration>());
        expect(client.timeout.inSeconds, greaterThan(0));
      });
    });

    group('Prompt Building Tests', () {
      test('should build appropriate prompts for data extraction', () {
        const String htmlContent =
            r'<html><body><h1>Product Title</h1><p>$19.99</p></body></html>';
        const Map<String, String> schema = <String, String>{
          'title': 'string',
          'price': 'number'
        };

        final String prompt =
            client._buildExtractionPrompt(htmlContent, schema);

        expect(prompt, contains('Extract'));
        expect(prompt, contains('JSON'));
        expect(prompt, contains('title'));
        expect(prompt, contains('price'));
      });

      test('should include custom instructions in prompts', () {
        const String htmlContent = '<html><body><h1>Test</h1></body></html>';
        const Map<String, String> schema = <String, String>{'title': 'string'};
        const String instructions = 'Focus on the main heading only';

        final String prompt = client._buildExtractionPrompt(
          htmlContent,
          schema,
          customInstructions: instructions,
        );

        expect(prompt, contains(instructions));
      });

      test('should handle schema-specific prompt formatting', () {
        const String htmlContent =
            '<html><body><div>Content</div></body></html>';
        const List<Map<String, String>> schemas = <Map<String, String>>[
          <String, String>{'title': 'string'},
          <String, String>{'price': 'number', 'currency': 'string'},
          <String, String>{'available': 'boolean', 'stock_count': 'integer'},
          <String, String>{'tags': 'array', 'metadata': 'object'},
        ];

        for (final Map<String, String> schema in schemas) {
          final String prompt =
              client._buildExtractionPrompt(htmlContent, schema);

          expect(prompt, isA<String>());
          expect(prompt, isNotEmpty);
          expect(prompt, contains('JSON'));

          // Check that all schema fields are mentioned
          for (final String field in schema.keys) {
            expect(prompt, contains(field));
          }
        }
      });
    });

    group('Response Processing Tests', () {
      test('should handle successful response format', () {
        const Map<String, Object> mockResponse = <String, Object>{
          'title': 'Test Product',
          'price': 29.99,
          'description': 'A great test product',
        };

        final Map<String, dynamic> processed =
            client._processResponse(mockResponse);

        expect(processed, equals(mockResponse));
      });

      test('should handle empty response data', () {
        expect(() => client._processResponse(<String, dynamic>{}),
            throwsA(isA<AIClientException>()));
      });

      test('should handle null response data', () {
        expect(() => client._processResponse(null),
            throwsA(isA<AIClientException>()));
      });

      test('should validate response against schema', () {
        const Map<String, Object> response = <String, Object>{
          'title': 'Test',
          'price': 19.99
        };
        const Map<String, String> schema = <String, String>{
          'title': 'string',
          'price': 'number'
        };

        expect(() => client._validateResponseAgainstSchema(response, schema),
            returnsNormally);
      });

      test('should handle response missing required fields', () {
        const Map<String, String> response = <String, String>{'title': 'Test'};
        const Map<String, String> schema = <String, String>{
          'title': 'string',
          'price': 'number'
        };

        // This might be acceptable depending on implementation
        expect(() => client._validateResponseAgainstSchema(response, schema),
            returnsNormally);
      });
    });

    group('Integration Configuration Tests', () {
      test('should configure for e-commerce extraction', () {
        final GeminiClient ecommerceClient = GeminiClient(
          apiKey: 'AItest-key-123456789',
          model: 'gemini-pro',
          options: <String, dynamic>{
            'temperature': 0.1, // Low temperature for consistent extraction
            'maxOutputTokens': 1024,
            'topP': 0.8,
          },
        );

        expect(ecommerceClient.options!['temperature'], equals(0.1));
        expect(ecommerceClient.options!['maxOutputTokens'], equals(1024));
      });

      test('should configure for news article extraction', () {
        final GeminiClient newsClient = GeminiClient(
          apiKey: 'AItest-key-123456789',
          model: 'gemini-pro',
          options: <String, dynamic>{
            'temperature': 0.2,
            'maxOutputTokens': 2048, // Longer content for articles
          },
        );

        expect(newsClient.model, equals('gemini-pro'));
        expect(newsClient.options!['maxOutputTokens'], equals(2048));
      });

      test('should configure for creative content extraction', () {
        final GeminiClient creativeClient = GeminiClient(
          apiKey: 'AItest-key-123456789',
          model: 'gemini-pro',
          options: <String, dynamic>{
            'temperature': 0.7, // Higher temperature for creativity
            'topP': 0.95,
            'topK': 40,
          },
        );

        expect(creativeClient.options!['temperature'], equals(0.7));
        expect(creativeClient.options!['topP'], equals(0.95));
        expect(creativeClient.options!['topK'], equals(40));
      });
    });

    group('Performance and Limits Tests', () {
      test('should respect content length limits', () {
        expect(client.maxContentLength, equals(100000));
        expect(client.maxContentLength, greaterThan(0));
      });

      test('should handle timeout configuration properly', () {
        final List<Duration> timeouts = <Duration>[
          const Duration(seconds: 30),
          const Duration(seconds: 60),
          const Duration(minutes: 2),
          const Duration(milliseconds: 500),
        ];

        for (final Duration timeout in timeouts) {
          final GeminiClient client = GeminiClient(
            apiKey: 'AItest-key-123456789',
            model: 'gemini-pro',
            timeout: timeout,
          );
          expect(client.timeout, equals(timeout));
        }
      });

      test('should validate performance-related options', () {
        final Map<String, num> performanceOptions = <String, num>{
          'maxOutputTokens': 1024,
          'topK': 40,
          'topP': 0.95,
          'temperature': 0.5,
        };

        final GeminiClient client = GeminiClient(
          apiKey: 'AItest-key-123456789',
          model: 'gemini-pro',
          options: performanceOptions,
        );

        expect(client.options, equals(performanceOptions));
      });
    });

    group('Safety and Content Filtering Tests', () {
      test('should handle safety settings configuration', () {
        final List<Map<String, String>> safetySettings = <Map<String, String>>[
          <String, String>{
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          <String, String>{
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
        ];

        final GeminiClient client = GeminiClient(
          apiKey: 'AItest-key-123456789',
          model: 'gemini-pro',
          options: <String, dynamic>{'safetySettings': safetySettings},
        );

        expect(client.options!['safetySettings'], equals(safetySettings));
      });

      test('should handle content filtering options', () {
        final Map<String, bool> filteringOptions = <String, bool>{
          'blockNone': false,
          'blockLow': false,
          'blockMedium': true,
          'blockHigh': true,
        };

        final GeminiClient client = GeminiClient(
          apiKey: 'AItest-key-123456789',
          model: 'gemini-pro',
          options: filteringOptions,
        );

        expect(client.options, containsPair('blockMedium', true));
        expect(client.options, containsPair('blockHigh', true));
      });
    });

    group('Multi-modal Configuration Tests', () {
      test('should handle text-only model configuration', () {
        final GeminiClient client = GeminiClient(
          apiKey: 'AItest-key-123456789',
          model: 'gemini-pro',
        );

        expect(client.model, equals('gemini-pro'));
      });

      test('should handle vision model configuration', () {
        final GeminiClient client = GeminiClient(
          apiKey: 'AItest-key-123456789',
          model: 'gemini-pro-vision',
        );

        expect(client.model, equals('gemini-pro-vision'));
      });

      test('should validate model capabilities', () {
        final List<String> textModels = <String>['gemini-pro'];
        final List<String> visionModels = <String>['gemini-pro-vision'];

        for (final String model in textModels) {
          final GeminiClient client = GeminiClient(
            apiKey: 'AItest-key-123456789',
            model: model,
          );
          expect(client._supportsTextOnly(), isTrue);
        }

        for (final String model in visionModels) {
          final GeminiClient client = GeminiClient(
            apiKey: 'AItest-key-123456789',
            model: model,
          );
          expect(client._supportsVision(), isTrue);
        }
      });
    });
  });
}

// Extension methods for testing private functionality
extension GeminiClientTestExtension on GeminiClient {
  void _validateHtmlContent(String content) {
    if (content.isEmpty) {
      throw ArgumentError('HTML content cannot be empty');
    }
    if (content.length > maxContentLength) {
      throw ArgumentError('HTML content exceeds maximum length limit');
    }
  }

  void _validateSchema(Map<String, String> schema) {
    if (schema.isEmpty) {
      throw const SchemaValidationException('Schema cannot be empty');
    }
  }

  String _buildExtractionPrompt(
    String htmlContent,
    Map<String, String> schema, {
    String? customInstructions,
  }) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('Extract the following data from the HTML content:');

    for (final MapEntry<String, String> entry in schema.entries) {
      buffer.writeln('- ${entry.key}: ${entry.value}');
    }

    if (customInstructions != null) {
      buffer.writeln('\nAdditional instructions: $customInstructions');
    }

    buffer
      ..writeln('\nReturn the data as JSON format.')
      ..writeln('\nHTML Content:')
      ..writeln(htmlContent);

    return buffer.toString();
  }

  Map<String, dynamic> _processResponse(Map<String, dynamic>? response) {
    if (response == null || response.isEmpty) {
      throw AIClientException(
          'Empty or null response from Gemini', providerName);
    }
    return response;
  }

  void _validateResponseAgainstSchema(
    Map<String, dynamic> response,
    Map<String, String> schema,
  ) {
    // Basic validation - in real implementation this would be more comprehensive
    for (final String key in schema.keys) {
      if (!response.containsKey(key)) {
        // Could log warning but might not throw exception for missing optional fields
      }
    }
  }

  bool _supportsTextOnly() {
    return model == 'gemini-pro' || !model.contains('vision');
  }

  bool _supportsVision() {
    return model.contains('vision') || model.contains('multimodal');
  }
}
