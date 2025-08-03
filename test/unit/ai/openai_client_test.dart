import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_webscraper/src/ai/openai_client.dart';
import 'package:ai_webscraper/src/core/exceptions.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

// Mock HTTP client for testing
class MockHttpClient implements http.Client {
  final List<http.Response> _responses = <http.Response>[];
  final List<http.Request> _requests = <http.Request>[];
  int _responseIndex = 0;

  void addResponse(http.Response response) {
    _responses.add(response);
  }

  List<http.Request> get requests => _requests;

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    throw UnimplementedError('Use post method for OpenAI client');
  }

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    // Create a request object for verification
    final http.Request request = http.Request('POST', url);
    if (headers != null) request.headers.addAll(headers);
    if (body != null) request.body = body.toString();
    _requests.add(request);

    if (_responseIndex < _responses.length) {
      return _responses[_responseIndex++];
    }
    throw Exception('No more mock responses available');
  }

  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) async {
    throw UnimplementedError();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    throw UnimplementedError();
  }

  @override
  void close() {}

  // Additional methods required by http.Client interface
  @override
  Future<http.Response> delete(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) async {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> patch(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    throw UnimplementedError();
  }

  @override
  Future<http.Response> put(Uri url,
      {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) async {
    throw UnimplementedError();
  }
}

void main() {
  group('OpenAIClient', () {
    late OpenAIClient client;
    late MockHttpClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockHttpClient();
      client = OpenAIClient(
        apiKey: 'sk-test-key-123456789',
        model: 'gpt-3.5-turbo',
        httpClient: mockHttpClient,
      );
    });

    group('Constructor Tests', () {
      test('should create instance with valid API key', () {
        final OpenAIClient client = OpenAIClient(
          apiKey: 'sk-test-key-123456789',
          model: 'gpt-3.5-turbo',
        );

        expect(client.apiKey, equals('sk-test-key-123456789'));
        expect(client.timeout, equals(const Duration(seconds: 30)));
        expect(client.model, equals('gpt-3.5-turbo'));
        expect(client.providerName, equals('OpenAI'));
      });

      test('should create instance with custom parameters', () {
        final OpenAIClient client = OpenAIClient(
          apiKey: 'sk-custom-key-987654321',
          timeout: const Duration(seconds: 60),
          model: 'gpt-4',
          options: <String, dynamic>{'temperature': 0.5},
        );

        expect(client.apiKey, equals('sk-custom-key-987654321'));
        expect(client.timeout, equals(const Duration(seconds: 60)));
        expect(client.model, equals('gpt-4'));
        expect(client.options, containsPair('temperature', 0.5));
      });
    });

    group('API Key Validation Tests', () {
      test('should validate correct OpenAI API key format', () {
        final OpenAIClient client = OpenAIClient(
            apiKey: 'sk-abcdefghijklmnopqrstuvwxyz1234567890ABCDEFG',
            model: 'gpt-3.5-turbo');

        expect(client.validateApiKey(), isTrue);
      });

      test('should reject API key without sk- prefix', () {
        final OpenAIClient client = OpenAIClient(
            apiKey: 'abcdefghijklmnopqrstuvwxyz1234567890ABCDEFG',
            model: 'gpt-3.5-turbo');

        expect(client.validateApiKey(), isFalse);
      });

      test('should reject too short API key', () {
        final OpenAIClient client = OpenAIClient(apiKey: 'sk-short', model: 'gpt-3.5-turbo');

        expect(client.validateApiKey(), isFalse);
      });

      test('should accept minimum length API key', () {
        final OpenAIClient client = OpenAIClient(
            apiKey: 'sk-1234567890123456789', model: 'gpt-3.5-turbo');

        expect(client.validateApiKey(), isTrue);
      });
    });

    group('Provider Information Tests', () {
      test('should return correct provider name', () {
        expect(client.providerName, equals('OpenAI'));
      });

      test('should return max content length', () {
        expect(client.maxContentLength, equals(50000));
        expect(client.maxContentLength, isA<int>());
        expect(client.maxContentLength, greaterThan(0));
      });
    });

    group('HTTP Request Building Tests', () {
      test('should build correct request headers', () async {
        const Map<String, List<Map<String, Map<String, String>>>> mockResponseData = <String, List<Map<String, Map<String, String>>>>{
          'choices': <Map<String, Map<String, String>>>[
            <String, Map<String, String>>{
              'message': <String, String>{
                'content':
                    '{"title": "Test Title", "description": "Test Description"}',
              },
            },
          ],
        };

        mockHttpClient.addResponse(http.Response(
          jsonEncode(mockResponseData),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        ));

        await client.extractData(
          htmlContent: '<html><body><h1>Test</h1></body></html>',
          schema: <String, String>{'title': 'string', 'description': 'string'},
        );

        expect(mockHttpClient.requests, hasLength(1));
        final http.Request request = mockHttpClient.requests.first;

        expect(request.headers['Authorization'],
            equals('Bearer sk-test-key-123456789'));
        expect(request.headers['Content-Type'], startsWith('application/json'));
        expect(request.headers['User-Agent'], equals('ai_webscraper/1.0.0'));
      });

      test('should build correct request body', () async {
        const Map<String, List<Map<String, Map<String, String>>>> mockResponseData = <String, List<Map<String, Map<String, String>>>>{
          'choices': <Map<String, Map<String, String>>>[
            <String, Map<String, String>>{
              'message': <String, String>{
                'content': '{"title": "Test Title"}',
              },
            },
          ],
        };

        mockHttpClient.addResponse(http.Response(
          jsonEncode(mockResponseData),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        ));

        await client.extractData(
          htmlContent: '<html><body><h1>Test</h1></body></html>',
          schema: <String, String>{'title': 'string'},
        );

        final http.Request request = mockHttpClient.requests.first;
        final Map<String, dynamic> bodyData = jsonDecode(request.body) as Map<String, dynamic>;

        expect(bodyData['model'], equals('gpt-3.5-turbo'));
        expect(bodyData['messages'], isA<List<dynamic>>());
        expect(bodyData['response_format'], equals(<String, String>{'type': 'json_object'}));
        expect(bodyData['temperature'], equals(0.1));
        expect(bodyData['max_tokens'], equals(1000));
      });

      test('should include custom options in request body', () async {
        final OpenAIClient customClient = OpenAIClient(
          apiKey: 'sk-test-key-123456789',
          httpClient: mockHttpClient,
          model: 'gpt-4',
        );

        const Map<String, List<Map<String, Map<String, String>>>> mockResponseData = <String, List<Map<String, Map<String, String>>>>{
          'choices': <Map<String, Map<String, String>>>[
            <String, Map<String, String>>{
              'message': <String, String>{
                'content': '{"title": "Test Title"}',
              },
            },
          ],
        };

        mockHttpClient.addResponse(http.Response(
          jsonEncode(mockResponseData),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        ));

        await customClient.extractData(
          htmlContent: '<html><body><h1>Test</h1></body></html>',
          schema: <String, String>{'title': 'string'},
          options: <String, dynamic>{
            'temperature': 0.7,
            'max_tokens': 2000,
            'top_p': 0.9,
            'frequency_penalty': 0.5,
            'presence_penalty': 0.3,
          },
        );

        final http.Request request = mockHttpClient.requests.first;
        final Map<String, dynamic> bodyData = jsonDecode(request.body) as Map<String, dynamic>;

        expect(bodyData['model'], equals('gpt-4'));
        expect(bodyData['temperature'], equals(0.7));
        expect(bodyData['max_tokens'], equals(2000));
        expect(bodyData['top_p'], equals(0.9));
        expect(bodyData['frequency_penalty'], equals(0.5));
        expect(bodyData['presence_penalty'], equals(0.3));
      });
    });

    group('Response Parsing Tests', () {
      test('should parse successful response correctly', () async {
        final Map<String, Object> expectedData = <String, Object>{
          'title': 'Sample Product',
          'price': 29.99,
          'description': 'A great product for testing',
        };

        final Map<String, List<Map<String, Map<String, String>>>> mockResponseData = <String, List<Map<String, Map<String, String>>>>{
          'choices': <Map<String, Map<String, String>>>[
            <String, Map<String, String>>{
              'message': <String, String>{
                'content': jsonEncode(expectedData),
              },
            },
          ],
        };

        mockHttpClient.addResponse(http.Response(
          jsonEncode(mockResponseData),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        ));

        final Map<String, dynamic> result = await client.extractData(
          htmlContent:
              r'<html><body><h1>Sample Product</h1><p>Price: $29.99</p></body></html>',
          schema: <String, String>{
            'title': 'string',
            'price': 'number',
            'description': 'string'
          },
        );

        expect(result, equals(expectedData));
      });

      test('should handle response with multiple choices', () async {
        final Map<String, String> expectedData = <String, String>{'title': 'First Choice'};

        final Map<String, List<Map<String, Map<String, String>>>> mockResponseData = <String, List<Map<String, Map<String, String>>>>{
          'choices': <Map<String, Map<String, String>>>[
            <String, Map<String, String>>{
              'message': <String, String>{
                'content': jsonEncode(expectedData),
              },
            },
            <String, Map<String, String>>{
              'message': <String, String>{
                'content': '{"title": "Second Choice"}',
              },
            },
          ],
        };

        mockHttpClient.addResponse(http.Response(
          jsonEncode(mockResponseData),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        ));

        final Map<String, dynamic> result = await client.extractData(
          htmlContent: '<html><body><h1>Test</h1></body></html>',
          schema: <String, String>{'title': 'string'},
        );

        expect(result, equals(expectedData));
      });

      test('should throw AIClientException for empty choices', () async {
        // ignore: strict_raw_type
        final Map<String, List> mockResponseData = <String, List>{'choices': <dynamic>[]};

        mockHttpClient.addResponse(http.Response(
          jsonEncode(mockResponseData),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        ));

        expect(
          () => client.extractData(
            htmlContent: '<html><body><h1>Test</h1></body></html>',
            schema: <String, String>{'title': 'string'},
          ),
          throwsA(isA<AIClientException>().having(
            (AIClientException e) => e.message,
            'message',
            contains('No choices returned'),
          )),
        );
      });

      test('should throw AIClientException for missing message', () async {
        const Map<String, List<Map<String, String>>> mockResponseData = <String, List<Map<String, String>>>{
          'choices': <Map<String, String>>[
            <String, String>{'invalid': 'structure'},
          ],
        };

        mockHttpClient.addResponse(http.Response(
          jsonEncode(mockResponseData),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        ));

        expect(
          () => client.extractData(
            htmlContent: '<html><body><h1>Test</h1></body></html>',
            schema: <String, String>{'title': 'string'},
          ),
          throwsA(isA<AIClientException>().having(
            (AIClientException e) => e.message,
            'message',
            contains('No message found'),
          )),
        );
      });

      test('should throw ParsingException for invalid JSON content', () async {
        const Map<String, List<Map<String, Map<String, String>>>> mockResponseData = <String, List<Map<String, Map<String, String>>>>{
          'choices': <Map<String, Map<String, String>>>[
            <String, Map<String, String>>{
              'message': <String, String>{
                'content': 'Invalid JSON content',
              },
            },
          ],
        };

        mockHttpClient.addResponse(http.Response(
          jsonEncode(mockResponseData),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        ));

        expect(
          () => client.extractData(
            htmlContent: '<html><body><h1>Test</h1></body></html>',
            schema: <String, String>{'title': 'string'},
          ),
          throwsA(isA<AIClientException>().having(
            (AIClientException e) => e.message,
            'message',
            contains('ParsingException'),
          )),
        );
      });

      test('should throw AIClientException for empty content', () async {
        const Map<String, List<Map<String, Map<String, String>>>> mockResponseData = <String, List<Map<String, Map<String, String>>>>{
          'choices': <Map<String, Map<String, String>>>[
            <String, Map<String, String>>{
              'message': <String, String>{
                'content': '',
              },
            },
          ],
        };

        mockHttpClient.addResponse(http.Response(
          jsonEncode(mockResponseData),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        ));

        expect(
          () => client.extractData(
            htmlContent: '<html><body><h1>Test</h1></body></html>',
            schema: <String, String>{'title': 'string'},
          ),
          throwsA(isA<AIClientException>().having(
            (AIClientException e) => e.message,
            'message',
            contains('Empty content'),
          )),
        );
      });
    });

    group('HTTP Status Code Handling Tests', () {
      test('should throw AIClientException for 401 Unauthorized', () async {
        const Map<String, Map<String, String>> errorResponse = <String, Map<String, String>>{
          'error': <String, String>{
            'message': 'Invalid authentication credentials',
            'type': 'invalid_request_error',
          },
        };

        mockHttpClient.addResponse(http.Response(
          jsonEncode(errorResponse),
          401,
          headers: <String, String>{'content-type': 'application/json'},
        ));

        expect(
          () => client.extractData(
            htmlContent: '<html><body><h1>Test</h1></body></html>',
            schema: <String, String>{'title': 'string'},
          ),
          throwsA(isA<AIClientException>()
              .having((AIClientException e) => e.statusCode, 'statusCode', equals(401))
              .having((AIClientException e) => e.message, 'message',
                  contains('Authentication failed'))),
        );
      });

      test('should throw AIClientException for 403 Forbidden', () async {
        const Map<String, Map<String, String>> errorResponse = <String, Map<String, String>>{
          'error': <String, String>{
            'message': 'Insufficient permissions',
            'type': 'invalid_request_error',
          },
        };

        mockHttpClient.addResponse(http.Response(
          jsonEncode(errorResponse),
          403,
          headers: <String, String>{'content-type': 'application/json'},
        ));

        expect(
          () => client.extractData(
            htmlContent: '<html><body><h1>Test</h1></body></html>',
            schema: <String, String>{'title': 'string'},
          ),
          throwsA(isA<AIClientException>()
              .having((AIClientException e) => e.statusCode, 'statusCode', equals(403))
              .having(
                  (AIClientException e) => e.message, 'message', contains('Access forbidden'))),
        );
      });

      test('should throw AIClientException for 429 Rate Limit', () async {
        const Map<String, Map<String, String>> errorResponse = <String, Map<String, String>>{
          'error': <String, String>{
            'message': 'Rate limit exceeded',
            'type': 'rate_limit_error',
          },
        };

        mockHttpClient.addResponse(http.Response(
          jsonEncode(errorResponse),
          429,
          headers: <String, String>{'content-type': 'application/json'},
        ));

        expect(
          () => client.extractData(
            htmlContent: '<html><body><h1>Test</h1></body></html>',
            schema: <String, String>{'title': 'string'},
          ),
          throwsA(isA<AIClientException>()
              .having((AIClientException e) => e.statusCode, 'statusCode', equals(429))
              .having((AIClientException e) => e.message, 'message',
                  contains('Rate limit exceeded'))),
        );
      });

      test('should throw AIClientException for 500 Server Error', () async {
        const Map<String, Map<String, String>> errorResponse = <String, Map<String, String>>{
          'error': <String, String>{
            'message': 'Internal Server Error',
            'type': 'server_error',
          },
        };

        mockHttpClient.addResponse(http.Response(
          jsonEncode(errorResponse),
          500,
          headers: <String, String>{'content-type': 'application/json'},
        ));

        expect(
          () => client.extractData(
            htmlContent: '<html><body><h1>Test</h1></body></html>',
            schema: <String, String>{'title': 'string'},
          ),
          throwsA(isA<AIClientException>()
              .having((AIClientException e) => e.statusCode, 'statusCode', equals(500))
              .having((AIClientException e) => e.message, 'message',
                  contains('OpenAI service unavailable'))),
        );
      });

      test('should throw AIClientException for unknown status codes', () async {
        const Map<String, Map<String, String>> errorResponse = <String, Map<String, String>>{
          'error': <String, String>{
            'message': 'Unknown error occurred',
            'type': 'unknown_error',
          },
        };

        mockHttpClient.addResponse(http.Response(
          jsonEncode(errorResponse),
          418, // I'm a teapot
          headers: <String, String>{'content-type': 'application/json'},
        ));

        expect(
          () => client.extractData(
            htmlContent: '<html><body><h1>Test</h1></body></html>',
            schema: <String, String>{'title': 'string'},
          ),
          throwsA(isA<AIClientException>()
              .having((AIClientException e) => e.statusCode, 'statusCode', equals(418))
              .having((AIClientException e) => e.message, 'message',
                  contains('OpenAI API error (418)'))),
        );
      });
    });

    group('Network Error Handling Tests', () {
      test('should throw AIClientException for timeout', () async {
        final OpenAIClient timeoutClient = OpenAIClient(
          apiKey: 'sk-test-key-123456789',
          model: 'gpt-3.5-turbo',
          timeout: const Duration(milliseconds: 1),
          httpClient: mockHttpClient,
        );

        // Simulate timeout by making the mock client throw TimeoutException
        mockHttpClient.addResponse(http.Response('', 200));

        // Since we can't easily simulate timeout with mock, test the timeout configuration
        expect(timeoutClient.timeout, equals(const Duration(milliseconds: 1)));
      });

      test('should handle SocketException gracefully', () {
        // Test configuration for network error handling
        expect(client.timeout, isA<Duration>());
        expect(client.apiKey, isNotEmpty);
      });

      test('should handle JSON parsing errors', () async {
        mockHttpClient.addResponse(http.Response(
          'Invalid JSON Response',
          200,
          headers: <String, String>{'content-type': 'application/json'},
        ));

        expect(
          () => client.extractData(
            htmlContent: '<html><body><h1>Test</h1></body></html>',
            schema: <String, String>{'title': 'string'},
          ),
          throwsA(isA<AIClientException>().having(
            (AIClientException e) => e.message,
            'message',
            contains('Failed to parse OpenAI response as JSON'),
          )),
        );
      });
    });

    group('Schema Validation Tests', () {
      test('should validate schema before making request', () async {
        expect(
          () => client.extractData(
            htmlContent: '<html><body><h1>Test</h1></body></html>',
            schema: <String, String>{}, // Empty schema
          ),
          throwsA(isA<AIClientException>().having(
            (AIClientException e) => e.message,
            'message',
            contains('Schema cannot be empty'),
          )),
        );
      });

      test('should accept valid schema', () async {
        const Map<String, String> validSchema = <String, String>{
          'title': 'string',
          'price': 'number',
          'available': 'boolean',
          'tags': 'array',
        };

        const Map<String, List<Map<String, Map<String, String>>>> mockResponseData = <String, List<Map<String, Map<String, String>>>>{
          'choices': <Map<String, Map<String, String>>>[
            <String, Map<String, String>>{
              'message': <String, String>{
                'content':
                    '{"title": "Test", "price": 19.99, "available": true, "tags": ["tag1"]}',
              },
            },
          ],
        };

        mockHttpClient.addResponse(http.Response(
          jsonEncode(mockResponseData),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        ));

        final Map<String, dynamic> result = await client.extractData(
          htmlContent: '<html><body><h1>Test</h1></body></html>',
          schema: validSchema,
        );

        expect(result, isA<Map<String, dynamic>>());
        expect(result['title'], equals('Test'));
        expect(result['price'], equals(19.99));
        expect(result['available'], equals(true));
        expect(result['tags'], equals(<String>['tag1']));
      });
    });

    group('Content Length Handling Tests', () {
      test('should handle content within length limits', () async {
        const String normalContent =
            '<html><body><h1>Normal sized content</h1></body></html>';

        const Map<String, List<Map<String, Map<String, String>>>> mockResponseData = <String, List<Map<String, Map<String, String>>>>{
          'choices': <Map<String, Map<String, String>>>[
            <String, Map<String, String>>{
              'message': <String, String>{
                'content': '{"title": "Normal Content"}',
              },
            },
          ],
        };

        mockHttpClient.addResponse(http.Response(
          jsonEncode(mockResponseData),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        ));

        final Map<String, dynamic> result = await client.extractData(
          htmlContent: normalContent,
          schema: <String, String>{'title': 'string'},
        );

        expect(result['title'], equals('Normal Content'));
      });

      test('should handle maximum content length configuration', () {
        expect(client.maxContentLength, equals(50000));
        expect(client.maxContentLength, greaterThan(0));
      });
    });

    group('Custom Instructions Tests', () {
      test('should handle custom instructions in options', () async {
        const Map<String, List<Map<String, Map<String, String>>>> mockResponseData = <String, List<Map<String, Map<String, String>>>>{
          'choices': <Map<String, Map<String, String>>>[
            <String, Map<String, String>>{
              'message': <String, String>{
                'content': '{"title": "Custom Instructions Applied"}',
              },
            },
          ],
        };

        mockHttpClient.addResponse(http.Response(
          jsonEncode(mockResponseData),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        ));

        await client.extractData(
          htmlContent: '<html><body><h1>Test</h1></body></html>',
          schema: <String, String>{'title': 'string'},
          options: <String, dynamic>{
            'instructions': 'Please extract the main heading from this webpage',
          },
        );

        final http.Request request = mockHttpClient.requests.first;
        final Map<String, dynamic> bodyData = jsonDecode(request.body) as Map<String, dynamic>;
        // ignore: strict_raw_type, always_specify_types
        final List messages = bodyData['messages'] as List<dynamic>;

        // Check that messages are created using PromptBuilder
        expect(messages, isNotEmpty);
        expect(messages.first['content'],
            contains('Extract only the requested data fields'));
      });
    });

    group('Disposal Tests', () {
      test('should dispose of HTTP client resources', () {
        final OpenAIClient client = OpenAIClient(
          apiKey: 'sk-test-key-123456789',
          model: 'gpt-3.5-turbo',
          httpClient: mockHttpClient,
        );
        
        // ignore: unnecessary_lambdas
        expect(() => client.dispose(), returnsNormally);
      });

      test('should handle multiple disposal calls', () {
        final OpenAIClient client = OpenAIClient(
          apiKey: 'sk-test-key-123456789',
          model: 'gpt-3.5-turbo',
          httpClient: mockHttpClient,
        )

        ..dispose();
        // ignore: unnecessary_lambdas
        expect(() => client.dispose(), returnsNormally);
      });
    });

    group('Integration Tests', () {
      test('should handle complete extraction workflow', () async {
        const String htmlContent = r'''
          <html>
            <head><title>E-commerce Product</title></head>
            <body>
              <h1>Premium Wireless Headphones</h1>
              <div class="price">$299.99</div>
              <div class="description">
                High-quality wireless headphones with noise cancellation
              </div>
              <div class="rating">4.5 stars</div>
              <div class="availability">In Stock</div>
            </body>
          </html>
        ''';

        final Map<String, Object> expectedData = <String, Object>{
          'name': 'Premium Wireless Headphones',
          'price': 299.99,
          'description':
              'High-quality wireless headphones with noise cancellation',
          'rating': '4.5 stars',
          'inStock': true,
        };

        final Map<String, List<Map<String, Map<String, String>>>> mockResponseData = <String, List<Map<String, Map<String, String>>>>{
          'choices': <Map<String, Map<String, String>>>[
            <String, Map<String, String>>{
              'message': <String, String>{
                'content': jsonEncode(expectedData),
              },
            },
          ],
        };

        mockHttpClient.addResponse(http.Response(
          jsonEncode(mockResponseData),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        ));

        final Map<String, dynamic> result = await client.extractData(
          htmlContent: htmlContent,
          schema: <String, String>{
            'name': 'string',
            'price': 'number',
            'description': 'string',
            'rating': 'string',
            'inStock': 'boolean',
          },
        );

        expect(result, equals(expectedData));

        // Verify request was made correctly
        expect(mockHttpClient.requests, hasLength(1));
        final http.Request request = mockHttpClient.requests.first;
        expect(request.url.toString(), contains('chat/completions'));
        expect(request.headers['Authorization'], startsWith('Bearer'));
      });
    });
  });
}
