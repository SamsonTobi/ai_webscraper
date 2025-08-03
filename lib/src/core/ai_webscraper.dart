// ignore_for_file: avoid_catches_without_on_clauses

import 'dart:async';
import 'dart:math';

import '../ai/ai_client_base.dart';
import '../ai/ai_client_factory.dart';
import '../scraping/javascript_scraper.dart';
import '../scraping/web_scraper.dart';
import '../utils/batch_processor.dart';
import '../utils/schema_validator.dart';
import '../utils/url_validator.dart';
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
  ///
  /// Throws [ArgumentError] if the API key is empty or invalid.
  /// Throws [UnsupportedProviderException] if the provider is not supported.
  AIWebScraper({
    required this.aiModel,
    required this.apiKey,
    this.timeout = const Duration(seconds: 30),
    this.useJavaScript = false,
    this.aiOptions,
  }) {
    if (apiKey.trim().isEmpty) {
      throw ArgumentError('API key cannot be empty');
    }

    _initializeComponents();
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
  void _initializeComponents() {
    // Create AI client
    _aiClient = AIClientFactory.create(
      aiModel,
      apiKey,
      timeout: timeout,
      options: aiOptions,
    );

    // Create scrapers
    _webScraper = WebScraper(timeout: timeout);
    _jsScraper = JavaScriptScraper(timeout: timeout);

    // Create validators and processors
    _schemaValidator = SchemaValidator();
    _urlValidator = URLValidator();
    _batchProcessor = BatchProcessor();
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
    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      // Validate inputs
      _urlValidator.validate(url);
      _schemaValidator.validate(schema);

      // Determine scraping method
      final bool shouldUseJS = useJavaScript ?? this.useJavaScript;

      // Attempt scraping with retries
      String? htmlContent;
      ScrapingException? lastScrapingError;

      for (int attempt = 0; attempt <= maxRetries; attempt++) {
        try {
          htmlContent = await _scrapeContent(url, shouldUseJS, attempt > 0);
          break; // Success, exit retry loop
        } catch (e) {
          lastScrapingError = e is ScrapingException
              ? e
              : ScrapingException(
                  'Scraping failed: $e',
                  url,
                );

          if (attempt == maxRetries) {
            // All retries exhausted
            throw lastScrapingError;
          }

          // Wait before retry with exponential backoff
          await Future<void>.delayed(
              Duration(milliseconds: 1000 * pow(2, attempt).toInt()));
        }
      }

      if (htmlContent == null) {
        throw lastScrapingError ??
            ScrapingException('Failed to scrape content', url);
      }

      // Extract data using AI
      final Map<String, dynamic> extractedData = await _aiClient.extractData(
        htmlContent: htmlContent,
        schema: schema,
        options: customInstructions != null
            ? <String, dynamic>{'instructions': customInstructions}
            : null,
      );

      stopwatch.stop();

      return ScrapingResult(
        success: true,
        data: extractedData,
        scrapingTime: stopwatch.elapsed,
        aiProvider: aiModel.provider,
        url: url,
      );
    } catch (e) {
      stopwatch.stop();

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
      // Try JavaScript scraping first
      try {
        return await _jsScraper.scrapeUrl(url);
      } catch (e) {
        // Fallback to HTTP scraping
        try {
          return await _webScraper.scrapeUrl(url);
        } catch (fallbackError) {
          // Both failed, throw the original JS error
          throw ScrapingException(
            'Both JavaScript and HTTP scraping failed. JS error: $e, HTTP error: $fallbackError',
            url,
          );
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
            return await _jsScraper.scrapeUrl(url);
          } catch (jsError) {
            // Both failed, throw the original HTTP error
            throw ScrapingException(
              'Both HTTP and JavaScript scraping failed. HTTP error: $e, JS error: $jsError',
              url,
            );
          }
        } else {
          // Don't fallback, just rethrow
          rethrow;
        }
      }
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

  /// Disposes of resources used by this scraper.
  ///
  /// Should be called when the scraper is no longer needed to free up resources.
  void dispose() {
    _jsScraper.dispose();
    // Note: WebScraper doesn't need explicit disposal
    // AI client disposal would be handled by the client itself if needed
  }
}
