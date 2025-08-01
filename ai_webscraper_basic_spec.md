# AI WebScraper - Basic Implementation

## Project Overview

A simplified Dart package that combines basic web scraping with AI-powered content extraction. This basic version focuses on core functionality with OpenAI integration and simple HTML scraping.

**Package Name**: `ai_webscraper`  
**Target Platforms**: Server-side Dart applications  
**License**: MIT

## Basic Features (v0.1.0)

- **Multiple AI Providers**: OpenAI GPT and Google Gemini integration
- **Basic Web Scraping**: HTTP requests with HTML parsing and JavaScript rendering
- **Schema-Based Extraction**: Simple JSON structure definition
- **Batch Processing**: Process multiple URLs concurrently
- **Type Safety**: Basic Dart type safety
- **Error Handling**: Simple error management

## Simplified Usage

```dart
final scraper = AIWebScraper(
  aiProvider: AIProvider.openai,
  apiKey: 'your-openai-api-key',
);

final result = await scraper.extractFromUrl(
  url: 'https://example.com',
  schema: {
    'title': 'string',
    'description': 'string',
    'price': 'number',
  },
);

if (result.success) {
  print('Extracted data: ${result.data}');
} else {
  print('Error: ${result.error}');
}
```

## Core Components

### 1. AIProvider Enum

```dart
enum AIProvider {
  openai,
  gemini,
}
```

### 2. AIWebScraper (Main Class)

```dart
class AIWebScraper {
  final AIProvider aiProvider;
  final String apiKey;
  final Duration timeout;

  AIWebScraper({
    required this.aiProvider,
    required this.apiKey,
    this.timeout = const Duration(seconds: 30),
  });

  Future<ScrapingResult> extractFromUrl({
    required String url,
    required Map<String, String> schema,
  });

  Future<List<ScrapingResult>> extractFromUrls({
    required List<String> urls,
    required Map<String, String> schema,
    int concurrency = 3,
  });
}
```

### 3. ScrapingResult

```dart
class ScrapingResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;
  final Duration scrapingTime;
  final AIProvider aiProvider;
  final String url;

  ScrapingResult({
    required this.success,
    this.data,
    this.error,
    required this.scrapingTime,
    required this.aiProvider,
    required this.url,
  });
}
```

### 4. Schema Types

```dart
enum SchemaType {
  string,
  number,
  boolean,
  array,
  object,
  date,
  url,
  email,
}
```

## Basic Dependencies

```yaml
name: ai_webscraper
description: A basic AI-powered web scraper for Dart
version: 0.1.0

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  http: ^1.1.0
  html: ^0.15.4
  meta: ^1.9.1
  puppeteer: ^3.5.0
  google_generative_ai: ^0.4.0

dev_dependencies:
  test: ^1.24.0
  lints: ^3.0.0
```

## Recommended Folder Structure

```
ai_webscraper/
├── lib/
│   ├── ai_webscraper.dart                 # Main export file
│   └── src/
│       ├── core/
│       │   ├── ai_webscraper.dart         # Main AIWebScraper class
│       │   ├── scraping_result.dart       # Result classes
│       │   ├── ai_provider.dart           # AI provider enum
│       │   ├── schema_type.dart           # Schema type enum
│       │   └── exceptions.dart            # Custom exceptions
│       ├── scraping/
│       │   ├── web_scraper.dart           # HTML scraping logic
│       │   ├── javascript_scraper.dart    # Puppeteer-based scraping
│       │   └── content_extractor.dart     # Content extraction utilities
│       ├── ai/
│       │   ├── ai_client_base.dart        # Abstract AI client interface
│       │   ├── openai_client.dart         # OpenAI API client
│       │   ├── gemini_client.dart         # Google Gemini API client
│       │   ├── ai_client_factory.dart     # Factory for AI clients
│       │   └── prompt_builder.dart        # AI prompt construction
│       └── utils/
│           ├── schema_validator.dart      # Schema validation
│           ├── url_validator.dart         # URL validation
│           ├── batch_processor.dart       # Batch processing utilities
│           └── logger.dart                # Basic logging
├── test/
│   ├── unit/
│   │   ├── core/
│   │   │   ├── ai_webscraper_test.dart
│   │   │   └── scraping_result_test.dart
│   │   ├── scraping/
│   │   │   ├── web_scraper_test.dart
│   │   │   └── javascript_scraper_test.dart
│   │   ├── ai/
│   │   │   ├── openai_client_test.dart
│   │   │   ├── gemini_client_test.dart
│   │   │   └── ai_client_factory_test.dart
│   │   └── utils/
│   │       ├── schema_validator_test.dart
│   │       └── batch_processor_test.dart
│   └── integration/
│       ├── end_to_end_test.dart
│       ├── batch_processing_test.dart
│       └── mock_server_test.dart
├── pubspec.yaml
├── README.md
├── CHANGELOG.md
├── LICENSE
└── analysis_options.yaml
```

## Implementation Plan

### Phase 1: Core Infrastructure (Week 1-2)

1. **Project Setup**

   - Create package structure
   - Set up dependencies
   - Configure linting and analysis

2. **Basic Web Scraping**

   - Implement HTTP client
   - Add HTML parsing
   - Create content extraction utilities

3. **OpenAI Integration**
   - Implement OpenAI API client
   - Create prompt building system
   - Add response parsing

### Phase 2: Core Features (Week 3-4)

1. **Main AIWebScraper Class**

   - Implement main scraping method
   - Add basic error handling
   - Create result structures
   - Implement batch processing

2. **Multiple AI Providers**

   - Implement OpenAI client
   - Implement Gemini client
   - Create AI client factory
   - Add provider-specific configurations

3. **JavaScript Scraping**

   - Integrate Puppeteer for dynamic content
   - Add fallback to basic HTTP scraping
   - Handle SPA and JavaScript-heavy sites

4. **Testing Foundation**
   - Unit tests for core components
   - Mock HTTP responses
   - Basic integration tests

### Phase 3: Polish & Examples (Week 5-6)

1. **Examples & Documentation**

   - Create usage examples
   - Write comprehensive README
   - Add API documentation

2. **Error Handling & Validation**

   - Improve error messages
   - Add input validation
   - Handle edge cases

3. **Performance & Reliability**
   - Add timeout handling
   - Implement retry logic
   - Basic rate limiting

## Basic File Implementations

### lib/ai_webscraper.dart

```dart
/// A basic AI-powered web scraper for Dart
library ai_webscraper;

export 'src/core/ai_webscraper.dart';
export 'src/core/scraping_result.dart';
export 'src/core/ai_provider.dart';
export 'src/core/schema_type.dart';
export 'src/core/exceptions.dart';
```

### lib/src/core/ai_provider.dart

```dart
enum AIProvider {
  openai,
  gemini,
}
```

### lib/src/core/schema_type.dart

```dart
enum SchemaType {
  string,
  number,
  boolean,
  array,
  object,
  date,
  url,
  email,
}
```

### lib/src/core/ai_webscraper.dart

```dart
import 'dart:async';
import '../scraping/web_scraper.dart';
import '../scraping/javascript_scraper.dart';
import '../ai/ai_client_factory.dart';
import '../ai/ai_client_base.dart';
import '../utils/schema_validator.dart';
import '../utils/batch_processor.dart';
import 'scraping_result.dart';
import 'ai_provider.dart';
import 'exceptions.dart';

class AIWebScraper {
  final AIProvider _aiProvider;
  final String _apiKey;
  final Duration _timeout;
  final WebScraper _webScraper;
  final JavaScriptScraper _jsScraper;
  final AIClientBase _aiClient;
  final SchemaValidator _schemaValidator;
  final BatchProcessor _batchProcessor;

  AIWebScraper({
    required AIProvider aiProvider,
    required String apiKey,
    Duration timeout = const Duration(seconds: 30),
  }) : _aiProvider = aiProvider,
       _apiKey = apiKey,
       _timeout = timeout,
       _webScraper = WebScraper(timeout: timeout),
       _jsScraper = JavaScriptScraper(timeout: timeout),
       _aiClient = AIClientFactory.create(aiProvider, apiKey),
       _schemaValidator = SchemaValidator(),
       _batchProcessor = BatchProcessor();

  Future<ScrapingResult> extractFromUrl({
    required String url,
    required Map<String, String> schema,
    bool useJavaScript = false,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // Validate inputs
      _schemaValidator.validate(schema);

      // Scrape web content
      String htmlContent;
      if (useJavaScript) {
        htmlContent = await _jsScraper.scrapeUrl(url);
      } else {
        try {
          htmlContent = await _webScraper.scrapeUrl(url);
        } catch (e) {
          // Fallback to JavaScript scraping
          htmlContent = await _jsScraper.scrapeUrl(url);
        }
      }

      // Extract data using AI
      final extractedData = await _aiClient.extractData(
        htmlContent: htmlContent,
        schema: schema,
      );

      stopwatch.stop();

      return ScrapingResult(
        success: true,
        data: extractedData,
        scrapingTime: stopwatch.elapsed,
        aiProvider: _aiProvider,
        url: url,
      );

    } catch (e) {
      stopwatch.stop();

      return ScrapingResult(
        success: false,
        error: e.toString(),
        scrapingTime: stopwatch.elapsed,
        aiProvider: _aiProvider,
        url: url,
      );
    }
  }

  Future<List<ScrapingResult>> extractFromUrls({
    required List<String> urls,
    required Map<String, String> schema,
    int concurrency = 3,
    bool continueOnError = true,
  }) async {
    return await _batchProcessor.processBatch(
      urls: urls,
      schema: schema,
      concurrency: concurrency,
      continueOnError: continueOnError,
      extractFunction: extractFromUrl,
    );
  }
}
```

### lib/src/core/scraping_result.dart

```dart
import 'ai_provider.dart';

class ScrapingResult {
  final bool success;
  final Map<String, dynamic>? data;
  final String? error;
  final Duration scrapingTime;
  final AIProvider aiProvider;
  final String url;

  const ScrapingResult({
    required this.success,
    this.data,
    this.error,
    required this.scrapingTime,
    required this.aiProvider,
    required this.url,
  });

  bool get hasData => data != null && data!.isNotEmpty;
  bool get hasError => error != null;

  @override
  String toString() {
    if (success) {
      return 'ScrapingResult(success: true, url: $url, provider: $aiProvider, data: $data, time: ${scrapingTime.inMilliseconds}ms)';
    } else {
      return 'ScrapingResult(success: false, url: $url, provider: $aiProvider, error: $error, time: ${scrapingTime.inMilliseconds}ms)';
    }
  }
}
```

### lib/src/ai/ai_client_base.dart

```dart
abstract class AIClientBase {
  Future<Map<String, dynamic>> extractData({
    required String htmlContent,
    required Map<String, String> schema,
  });
}
```

### lib/src/ai/ai_client_factory.dart

```dart
import '../core/ai_provider.dart';
import 'ai_client_base.dart';
import 'openai_client.dart';
import 'gemini_client.dart';

class AIClientFactory {
  static AIClientBase create(AIProvider provider, String apiKey) {
    switch (provider) {
      case AIProvider.openai:
        return OpenAIClient(apiKey: apiKey);
      case AIProvider.gemini:
        return GeminiClient(apiKey: apiKey);
    }
  }
}
```

### lib/src/ai/openai_client.dart

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_client_base.dart';

class OpenAIClient extends AIClientBase {
  final String apiKey;
  final String baseUrl = 'https://api.openai.com/v1';

  OpenAIClient({required this.apiKey});

  @override
  Future<Map<String, dynamic>> extractData({
    required String htmlContent,
    required Map<String, String> schema,
  }) async {
    final prompt = _buildPrompt(htmlContent, schema);

    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'system', 'content': 'You are a web scraping assistant. Extract data from HTML and return valid JSON.'},
          {'role': 'user', 'content': prompt},
        ],
        'response_format': {'type': 'json_object'},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenAI API error: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'];
    return jsonDecode(content);
  }

  String _buildPrompt(String htmlContent, Map<String, String> schema) {
    final schemaDescription = schema.entries
        .map((e) => '- ${e.key}: ${e.value}')
        .join('\n');

    return '''
Extract the following data from this HTML content and return as JSON:

Schema:
$schemaDescription

HTML Content:
$htmlContent

Return only valid JSON with the requested fields.
''';
  }
}
```

### lib/src/ai/gemini_client.dart

```dart
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'ai_client_base.dart';

class GeminiClient extends AIClientBase {
  final String apiKey;
  late final GenerativeModel model;

  GeminiClient({required this.apiKey}) {
    model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: apiKey,
    );
  }

  @override
  Future<Map<String, dynamic>> extractData({
    required String htmlContent,
    required Map<String, String> schema,
  }) async {
    final prompt = _buildPrompt(htmlContent, schema);

    final response = await model.generateContent([Content.text(prompt)]);

    if (response.text == null) {
      throw Exception('Gemini API error: No response text');
    }

    try {
      return jsonDecode(response.text!);
    } catch (e) {
      throw Exception('Failed to parse Gemini response as JSON: ${response.text}');
    }
  }

  String _buildPrompt(String htmlContent, Map<String, String> schema) {
    final schemaDescription = schema.entries
        .map((e) => '- ${e.key}: ${e.value}')
        .join('\n');

    return '''
Extract the following data from this HTML content and return as valid JSON:

Schema:
$schemaDescription

HTML Content:
$htmlContent

Return only valid JSON with the requested fields. Do not include any explanatory text.
''';
  }
}
```

### lib/src/utils/batch_processor.dart

```dart
import 'dart:async';
import '../core/scraping_result.dart';

class BatchProcessor {
  Future<List<ScrapingResult>> processBatch({
    required List<String> urls,
    required Map<String, String> schema,
    required int concurrency,
    required bool continueOnError,
    required Future<ScrapingResult> Function({
      required String url,
      required Map<String, String> schema,
    }) extractFunction,
  }) async {
    final results = <ScrapingResult>[];
    final semaphore = Semaphore(concurrency);

    final futures = urls.map((url) async {
      await semaphore.acquire();

      try {
        final result = await extractFunction(url: url, schema: schema);
        return result;
      } catch (e) {
        if (!continueOnError) {
          rethrow;
        }
        return ScrapingResult(
          success: false,
          error: e.toString(),
          scrapingTime: Duration.zero,
          aiProvider: AIProvider.openai, // Default fallback
          url: url,
        );
      } finally {
        semaphore.release();
      }
    });

    final completedResults = await Future.wait(futures);
    results.addAll(completedResults);

    return results;
  }
}

class Semaphore {
  final int maxCount;
  int _currentCount;
  final Queue<Completer<void>> _waitQueue = Queue<Completer<void>>();

  Semaphore(this.maxCount) : _currentCount = maxCount;

  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeFirst();
      completer.complete();
    } else {
      _currentCount++;
    }
  }
}
```

## Testing Strategy

### Unit Tests

- Test each component in isolation
- Mock external dependencies (HTTP, OpenAI API)
- Validate schema parsing and validation
- Test error handling scenarios

### Integration Tests

- End-to-end scraping workflows
- Real HTTP requests to test sites
- OpenAI API integration (with test keys)
- Performance and timeout testing

### Example Test Structure

```dart
// test/unit/core/ai_webscraper_test.dart
import 'package:test/test.dart';
import 'package:ai_webscraper/ai_webscraper.dart';

void main() {
  group('AIWebScraper', () {
    test('should create instance with valid API key and OpenAI provider', () {
      expect(
        () => AIWebScraper(
          aiProvider: AIProvider.openai,
          apiKey: 'test-key',
        ),
        returnsNormally,
      );
    });

    test('should create instance with valid API key and Gemini provider', () {
      expect(
        () => AIWebScraper(
          aiProvider: AIProvider.gemini,
          apiKey: 'test-key',
        ),
        returnsNormally,
      );
    });

    test('should handle batch processing', () async {
      final scraper = AIWebScraper(
        aiProvider: AIProvider.openai,
        apiKey: 'test-key',
      );

      final urls = [
        'https://example1.com',
        'https://example2.com',
      ];

      final results = await scraper.extractFromUrls(
        urls: urls,
        schema: {'title': 'string'},
        concurrency: 2,
      );

      expect(results, hasLength(2));
    });

    test('should throw exception with invalid schema', () async {
      final scraper = AIWebScraper(
        aiProvider: AIProvider.openai,
        apiKey: 'test-key',
      );

      expect(
        () => scraper.extractFromUrl(
          url: 'https://example.com',
          schema: {}, // Empty schema should be invalid
        ),
        throwsA(isA<SchemaValidationException>()),
      );
    });
  });
}
```

## Example Usage

### Basic E-commerce Product Extraction

```dart
import 'package:ai_webscraper/ai_webscraper.dart';

void main() async {
  final scraper = AIWebScraper(
    aiProvider: AIProvider.openai,
    apiKey: 'your-openai-api-key',
  );

  final result = await scraper.extractFromUrl(
    url: 'https://example-store.com/product/123',
    schema: {
      'name': 'string',
      'price': 'number',
      'description': 'string',
      'inStock': 'boolean',
    },
  );

  if (result.success) {
    print('Product: ${result.data!['name']}');
    print('Price: \$${result.data!['price']}');
    print('Available: ${result.data!['inStock']}');
  } else {
    print('Scraping failed: ${result.error}');
  }
}
```

### Batch Processing Example

```dart
void main() async {
  final scraper = AIWebScraper(
    aiProvider: AIProvider.gemini,
    apiKey: 'your-gemini-api-key',
  );

  final urls = [
    'https://store1.com/product/1',
    'https://store2.com/product/2',
    'https://store3.com/product/3',
  ];

  final results = await scraper.extractFromUrls(
    urls: urls,
    schema: {
      'name': 'string',
      'price': 'number',
    },
    concurrency: 2,
    continueOnError: true,
  );

  for (final result in results) {
    if (result.success) {
      print('${result.url}: ${result.data}');
    } else {
      print('Failed ${result.url}: ${result.error}');
    }
  }
}
```

### News Article Extraction

```dart
final result = await scraper.extractFromUrl(
  url: 'https://news-site.com/article/123',
  schema: {
    'headline': 'string',
    'author': 'string',
    'publishDate': 'string',
    'content': 'string',
    'tags': 'array',
  },
  useJavaScript: true, // Enable for dynamic content
);
```

## Future Enhancements (v0.2.0+)

1. **Additional AI Providers**: Anthropic Claude
2. **Advanced Scraping Strategies**: Stealth mode, proxy support
3. **Caching System**: Memory and disk caching
4. **Custom Prompts**: User-defined extraction prompts
5. **Configuration Options**: Advanced timeouts, retries, rate limiting
6. **Middleware System**: Request/response interceptors
7. **Performance Monitoring**: Detailed metrics and analytics

This basic implementation provides a solid foundation for an AI-powered web scraper with multiple AI providers, JavaScript rendering support, and batch processing capabilities while keeping complexity manageable for initial development and testing.
