// ignore_for_file: avoid_catches_without_on_clauses, strict_raw_type

import 'dart:async';
import 'dart:math';

import 'package:ai_webscraper/src/ai/ai_client_base.dart';
import 'package:ai_webscraper/src/ai/ai_client_factory.dart';
import 'package:ai_webscraper/src/scraping/javascript_scraper.dart';
import 'package:ai_webscraper/src/scraping/web_scraper.dart';
import 'package:ai_webscraper/src/utils/batch_processor.dart';
import 'package:ai_webscraper/src/utils/logger.dart';
import 'package:ai_webscraper/src/utils/response_cache.dart';
import 'package:ai_webscraper/src/utils/schema_validator.dart';
import 'package:ai_webscraper/src/utils/url_validator.dart';
import 'ai_model.dart';
import 'exceptions.dart';
import 'scraping_result.dart';

/// Main AI-powered web scraper class.
///
/// This class provides the core functionality for scraping web content
/// and extracting structured data using AI providers like OpenAI and Gemini.
///
/// Features:
/// - Multiple AI provider support (OpenAI, Gemini)
/// - Automatic fallback from HTTP to JavaScript scraping
/// - Batch processing with concurrency control
/// - Comprehensive error handling and timeout management
/// - Schema validation for structured data extraction
///
/// Example usage:
/// ```dart
/// final scraper = AIWebScraper(
///   aiModel: AIModel.gpt4o,
///   apiKey: 'your-openai-api-key',
/// );
///
/// final result = await scraper.extractFromUrl(
///   url: 'https://example.com',
///   schema: {'title': 'string', 'price': 'number'},
/// );
/// ```
class AIWebScraper {
  /// Creates a new AIWebScraper instance.
  ///
  /// [aiModel] - The specific AI model to use (e.g., AIModel.gpt4o, AIModel.gemini15Pro)
  /// [apiKey] - The API key for the AI provider
  /// [timeout] - Timeout duration for operations (default: 30 seconds)
  /// [useJavaScript] - Whether to use JavaScript scraping by default
  /// [aiOptions] - Additional options for the AI provider
  /// [enableCache] - Whether to enable response caching (default: true)
  /// [cacheFilePath] - Optional file path for persistent caching
  /// [cacheMaxAge] - Maximum age for cache entries (default: 1 hour)
  ///
  /// Throws [ArgumentError] if the API key is empty or invalid.
  /// Throws [UnsupportedProviderException] if the provider is not supported.
  AIWebScraper({
    required this.aiModel,
    required this.apiKey,
    this.timeout = const Duration(seconds: 30),
    this.useJavaScript = false,
    this.aiOptions,
    bool enableCache = true,
    String? cacheFilePath,
    Duration cacheMaxAge = const Duration(hours: 1),
  }) : _cache = enableCache
            ? ResponseCache(
                cacheFilePath: cacheFilePath,
                maxAge: cacheMaxAge,
              )
            : null {
    if (apiKey.trim().isEmpty) {
      throw ArgumentError('API key cannot be empty');
    }

    // Note: _initializeComponents() is async and will be called in extractFromUrl if needed
  }

  /// The AI model used for content extraction.
  final AIModel aiModel;

  /// The API key for the AI provider.
  final String apiKey;

  /// Timeout duration for scraping operations.
  final Duration timeout;

  /// Whether to use JavaScript scraping by default.
  final bool useJavaScript;

  /// Additional options for the AI provider.
  final Map<String, dynamic>? aiOptions;

  /// The response cache for storing AI responses.
  final ResponseCache? _cache;

  /// Logger for this scraper.
  static final ScopedLogger _logger = Logger.scoped('AIWebScraper');

  /// Whether the components have been initialized.
  bool _initialized = false;

  /// The AI client instance.
  late final AIClientBase _aiClient;

  /// The HTTP-based web scraper.
  late final WebScraper _webScraper;

  /// The JavaScript-based web scraper.
  late final JavaScriptScraper _jsScraper;

  /// The schema validator.
  late final SchemaValidator _schemaValidator;

  /// The URL validator.
  late final URLValidator _urlValidator;

  /// The batch processor.
  late final BatchProcessor _batchProcessor;

  /// Initializes all internal components.
  Future<void> _initializeComponents() async {
    // Initialize cache if enabled
    if (_cache != null) {
      await _cache!.initialize();
      _logger.info('Response cache initialized');
    }

    // Create AI client with cache
    _aiClient = AIClientFactory.create(
      aiModel,
      apiKey,
      timeout: timeout,
      options: aiOptions,
      cache: _cache,
    );
    _logger.info('AI client initialized for provider: ${aiModel.provider}');

    // Create scrapers
    _webScraper = WebScraper(timeout: timeout);
    _jsScraper = JavaScriptScraper(timeout: timeout);

    // Create validators and processors
    _schemaValidator = SchemaValidator();
    _urlValidator = URLValidator();
    _batchProcessor = BatchProcessor();

    _logger.info('AIWebScraper initialization complete');
  }

  /// Extracts structured data from a single URL.
  ///
  /// [url] - The URL to scrape
  /// [schema] - The schema defining what data to extract
  /// [useJavaScript] - Whether to use JavaScript scraping (overrides default)
  /// [customInstructions] - Additional instructions for the AI
  /// [maxRetries] - Maximum number of retry attempts (default: 2)
  ///
  /// Returns a [ScrapingResult] containing the extracted data or error information.
  ///
  /// Throws [ArgumentError] if the URL or schema is invalid.
  Future<ScrapingResult> extractFromUrl({
    required String url,
    required Map<String, String> schema,
    bool? useJavaScript,
    String? customInstructions,
    int maxRetries = 2,
  }) async {
    // Initialize components if not already done
    if (!_initialized) {
      await _initializeComponents();
      _initialized = true;
    }

    final Stopwatch stopwatch = Stopwatch()..start();
    _logger.info('Starting extraction for URL: $url');

    try {
      // Validate inputs
      _urlValidator.validate(url);
      _schemaValidator.validate(schema);

      // Determine scraping method
      final bool shouldUseJS = useJavaScript ?? this.useJavaScript;
      _logger.debug('Using JavaScript scraping: $shouldUseJS');

      // Attempt scraping with retries
      String? htmlContent;
      ScrapingException? lastScrapingError;

      for (int attempt = 0; attempt <= maxRetries; attempt++) {
        try {
          _logger.debug('Scraping attempt ${attempt + 1}/${maxRetries + 1}');
          htmlContent = await _scrapeContent(url, shouldUseJS, attempt > 0);
          break; // Success, exit retry loop
        } catch (e) {
          lastScrapingError = e is ScrapingException
              ? e
              : ScrapingException(
                  'Scraping failed: $e',
                  url,
                );

          _logger.warning('Scraping attempt ${attempt + 1} failed: $e');

          if (attempt == maxRetries) {
            // All retries exhausted
            throw lastScrapingError;
          }

          // Wait before retry with exponential backoff
          final Duration delay = Duration(milliseconds: 1000 * pow(2, attempt).toInt());
          _logger.debug('Waiting ${delay.inMilliseconds}ms before retry');
          await Future<void>.delayed(delay);
        }
      }

      if (htmlContent == null) {
        throw lastScrapingError ??
            ScrapingException('Failed to scrape content', url);
      }

      // Log the raw HTML content before passing to AI
      _logger..info(
          'Successfully scraped content (${htmlContent.length} characters)')
      ..debug(
          'Raw HTML content: ${htmlContent.substring(0, min(1000, htmlContent.length))}${htmlContent.length > 1000 ? '...' : ''}')

      // Print/log the raw HTML content before passing to AI
      // You can replace this with your preferred logger
      ..debug('--- RAW HTML CONTENT BEFORE AI PARSING ---')
      ..debug(htmlContent)
      ..debug('--- END RAW HTML CONTENT ---');

      // Extract data using AI
      final Map<String, dynamic> extractedData = await _aiClient.extractData(
        htmlContent: htmlContent,
        schema: schema,
        options: customInstructions != null
            ? <String, dynamic>{'instructions': customInstructions}
            : null,
      );

      stopwatch.stop();
      _logger.info(
          'Successfully extracted data in ${stopwatch.elapsedMilliseconds}ms');

      return ScrapingResult(
        success: true,
        data: extractedData,
        scrapingTime: stopwatch.elapsed,
        aiProvider: aiModel.provider,
        url: url,
      );
    } catch (e) {
      stopwatch.stop();
      _logger.error(
          'Extraction failed after ${stopwatch.elapsedMilliseconds}ms', e);

      return ScrapingResult(
        success: false,
        error: e.toString(),
        scrapingTime: stopwatch.elapsed,
        aiProvider: aiModel.provider,
        url: url,
      );
    }
  }

  /// Extracts structured data from multiple URLs concurrently.
  ///
  /// [urls] - List of URLs to scrape
  /// [schema] - The schema defining what data to extract
  /// [concurrency] - Maximum number of concurrent operations (default: 3)
  /// [continueOnError] - Whether to continue processing if individual URLs fail
  /// [useJavaScript] - Whether to use JavaScript scraping (overrides default)
  /// [customInstructions] - Additional instructions for the AI
  /// [maxRetries] - Maximum number of retry attempts per URL (default: 2)
  ///
  /// Returns a list of [ScrapingResult] objects, one for each URL.
  ///
  /// Throws [ArgumentError] if inputs are invalid.
  /// Throws [BatchProcessingException] if batch processing fails critically.
  Future<List<ScrapingResult>> extractFromUrls({
    required List<String> urls,
    required Map<String, String> schema,
    int concurrency = 3,
    bool continueOnError = true,
    bool? useJavaScript,
    String? customInstructions,
    int maxRetries = 2,
  }) async {
    if (urls.isEmpty) {
      throw ArgumentError('URLs list cannot be empty');
    }

    if (concurrency < 1) {
      throw ArgumentError('Concurrency must be at least 1');
    }

    try {
      // Validate all URLs upfront
      for (final String url in urls) {
        _urlValidator.validate(url);
      }

      // Validate schema once
      _schemaValidator.validate(schema);

      // Process URLs in batches
      return await _batchProcessor.processBatch<ScrapingResult>(
        items: urls,
        processor: (String url) => extractFromUrl(
          url: url,
          schema: schema,
          useJavaScript: useJavaScript,
          customInstructions: customInstructions,
          maxRetries: maxRetries,
        ),
        concurrency: concurrency,
        continueOnError: continueOnError,
      );
    } catch (e) {
      if (e is ArgumentError) {
        rethrow;
      }

      throw BatchProcessingException(
        'Batch processing failed: $e',
        0, // Will be updated by batch processor
        urls.length,
      );
    }
  }

  /// Internal method to scrape content from a URL.
  ///
  /// Implements fallback logic from HTTP to JavaScript scraping.
  Future<String> _scrapeContent(String url, bool preferJS, bool isRetry) async {
    if (preferJS) {
      // Try JavaScript scraping first with comprehensive extraction
      try {
        final Map<String, dynamic> comprehensiveData = await _jsScraper.scrapeUrlComprehensive(url);
        return _formatComprehensiveData(comprehensiveData);
      } catch (e) {
        // Fallback to basic JavaScript scraping
        try {
          return await _jsScraper.scrapeUrl(url);
        } catch (jsError) {
          // Finally, fallback to HTTP scraping
          try {
            return await _webScraper.scrapeUrl(url);
          } catch (fallbackError) {
            // All methods failed, throw the most informative error
            throw ScrapingException(
              'All scraping methods failed. Comprehensive JS: $e, Basic JS: $jsError, HTTP: $fallbackError',
              url,
            );
          }
        }
      }
    } else {
      // Try HTTP scraping first
      try {
        return await _webScraper.scrapeUrl(url);
      } catch (e) {
        // If it's a retry or specific error patterns, try JavaScript
        if (isRetry || _shouldFallbackToJS(e)) {
          try {
            // Use comprehensive extraction for dynamic content
            final Map<String, dynamic> comprehensiveData =
                await _jsScraper.scrapeUrlComprehensive(url);
            return _formatComprehensiveData(comprehensiveData);
          } catch (jsComprehensiveError) {
            try {
              // Fallback to basic JavaScript scraping
              return await _jsScraper.scrapeUrl(url);
            } catch (jsError) {
              // Both failed, throw the original HTTP error
              throw ScrapingException(
                'All fallback methods failed. HTTP: $e, Comprehensive JS: $jsComprehensiveError, Basic JS: $jsError',
                url,
              );
            }
          }
        } else {
          // Don't fallback, just rethrow
          rethrow;
        }
      }
    }
  }

  /// Formats comprehensive extraction data into a readable format for AI processing.
  String _formatComprehensiveData(Map<String, dynamic> data) {
    final StringBuffer buffer = StringBuffer()

    // Add basic page info
    ..writeln('=== PAGE INFORMATION ===')
    ..writeln('Title: ${data['title'] ?? 'N/A'}')
    ..writeln('URL: ${data['url'] ?? 'N/A'}')
    ..writeln();

    // Add meta information
    if (data['meta'] != null) {
      final Map<String, dynamic> meta = data['meta'] as Map<String, dynamic>;
      buffer.writeln('=== META DATA ===');
      if (meta['description'] != null) {
        buffer.writeln('Description: ${meta['description']}');
      }
      if (meta['keywords'] != null) {
        buffer.writeln('Keywords: ${meta['keywords']}');
      }
      buffer.writeln();
    }

    // Add structured data if available
    if (data['eventContent'] != null) {
      final Map<String, dynamic> eventContent = data['eventContent'] as Map<String, dynamic>;
      buffer.writeln('=== EVENT CONTENT ===');

      // Add structured data
      if (eventContent['structuredData'] != null) {
        buffer..writeln('Structured Data:')
        ..writeln(eventContent['structuredData'].toString())
        ..writeln();
      }

      // Add event-specific elements
      _addElementSection(buffer, 'Event Cards', eventContent['cards']);
      _addElementSection(buffer, 'Schedule Items', eventContent['schedule']);
      _addElementSection(buffer, 'Sessions', eventContent['sessions']);
      _addElementSection(buffer, 'Speakers', eventContent['speakers']);
      _addElementSection(buffer, 'Times/Dates', eventContent['times']);
    }

    // Add headings
    if (data['headings'] != null) {
      final Map<String, dynamic> headings = data['headings'] as Map<String, dynamic>;
      buffer.writeln('=== HEADINGS ===');
      for (final MapEntry<String, dynamic> entry in headings.entries) {
        final List elements = entry.value as List;
        if (elements.isNotEmpty) {
          buffer.writeln('${entry.key.toUpperCase()}:');
          for (final element in elements) {
            if (element['text'] != null &&
                element['text'].toString().trim().isNotEmpty) {
              buffer.writeln('  - ${element['text']}');
            }
          }
        }
      }
      buffer.writeln();
    }

    // Add significant content sections
    if (data['divs'] != null) {
      final List divs = data['divs'] as List;
      if (divs.isNotEmpty) {
        buffer.writeln('=== CONTENT SECTIONS ===');
        for (final div in divs.take(20)) {
          // Limit to first 20 significant divs
          if (div['text'] != null && div['text'].toString().trim().isNotEmpty) {
            final String text = div['text'].toString().trim();
            if (text.length > 20) {
              // Only include substantial content
              buffer..writeln(
                  'Section: ${text.length > 500 ? '${text.substring(0, 500)}...' : text}')
              ..writeln('---');
            }
          }
        }
        buffer.writeln();
      }
    }

    // Add links
    if (data['links'] != null) {
      final List links = data['links'] as List;
      if (links.isNotEmpty) {
        buffer.writeln('=== LINKS ===');
        for (final link in links.take(50)) {
          // Limit to first 50 links
          final String? text = link['text']?.toString().trim();
          final String? href = link['attributes']?['href']?.toString();
          if (text != null && text.isNotEmpty && href != null) {
            buffer.writeln('Link: $text -> $href');
          }
        }
        buffer.writeln();
      }
    }

    // Add page statistics
    if (data['stats'] != null) {
      final Map<String, dynamic> stats = data['stats'] as Map<String, dynamic>;
      buffer..writeln('=== PAGE STATISTICS ===')
      ..writeln('Total Elements: ${stats['totalElements'] ?? 'N/A'}')
      ..writeln('Total Text Length: ${stats['totalTextLength'] ?? 'N/A'}')
      ..writeln('Total Links: ${stats['totalLinks'] ?? 'N/A'}')
      ..writeln('Has React Root: ${stats['hasReactRoot'] ?? false}');
      if (stats['rootContent'] != null &&
          stats['rootContent'].toString().trim().isNotEmpty) {
        buffer..writeln('React Root Content Preview:')
        ..writeln(stats['rootContent']);
      }
      buffer.writeln();
    }

    // Add raw body text as fallback
    if (data['bodyText'] != null &&
        data['bodyText'].toString().trim().isNotEmpty) {
      buffer.writeln('=== FULL PAGE TEXT ===');
      final String bodyText = data['bodyText'].toString();
      buffer.writeln(bodyText.length > 5000
          ? '${bodyText.substring(0, 5000)}...'
          : bodyText);
    }

    return buffer.toString();
  }

  /// Helper method to add element sections to the formatted output.
  void _addElementSection(StringBuffer buffer, String title, dynamic elements) {
    if (elements != null && elements is List && elements.isNotEmpty) {
      buffer.writeln('$title:');
      for (final element in elements.take(10)) {
        // Limit to first 10 elements
        if (element['text'] != null &&
            element['text'].toString().trim().isNotEmpty) {
          buffer.writeln('  - ${element['text']}');
        }
      }
      buffer.writeln();
    }
  }

  /// Determines if we should fallback to JavaScript scraping based on the error.
  bool _shouldFallbackToJS(dynamic error) {
    final String errorString = error.toString().toLowerCase();

    // Common patterns that indicate dynamic content
    return errorString.contains('javascript') ||
        errorString.contains('js') ||
        errorString.contains('dynamic') ||
        errorString.contains('react') ||
        errorString.contains('vue') ||
        errorString.contains('angular') ||
        errorString.contains('spa') ||
        errorString.contains('empty') ||
        errorString.contains('no content');
  }

  /// Gets information about the AI provider being used.
  String get providerInfo => _aiClient.providerName;

  /// Gets the maximum content length supported by the AI provider.
  int? get maxContentLength => _aiClient.maxContentLength;

  /// Validates the API key format for the current provider.
  bool validateApiKey() => _aiClient.validateApiKey();

  /// Gets cache statistics if caching is enabled.
  Map<String, dynamic>? getCacheStats() {
    return _cache?.getStats();
  }

  /// Clears the response cache if caching is enabled.
  Future<void> clearCache() async {
    if (_cache != null) {
      await _cache!.clear();
      _logger.info('Response cache cleared');
    }
  }

  /// Disposes of resources used by this scraper.
  ///
  /// Should be called when the scraper is no longer needed to free up resources.
  Future<void> dispose() async {
    _logger.info('Disposing AIWebScraper resources');

    // Dispose of scrapers
    await _jsScraper.dispose();

    // Dispose of cache
    if (_cache != null) {
      await _cache!.dispose();
    }

    _logger.info('AIWebScraper disposed');
    // Note: WebScraper doesn't need explicit disposal
    // AI client disposal would be handled by the client itself if needed
  }
}
