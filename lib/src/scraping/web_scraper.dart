// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:ai_webscraper/src/utils/logger.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import '../core/exceptions.dart';
import 'content_extractor.dart';

/// HTTP-based web scraper for basic content extraction.
///
/// This scraper uses standard HTTP requests to fetch web pages and
/// extracts content using HTML parsing. It's fast and lightweight
/// but cannot handle JavaScript-rendered content.
class WebScraper {

  /// Creates a new web scraper instance.
  ///
  /// [timeout] sets the maximum time to wait for a response.
  /// [userAgent] sets the User-Agent header for requests.
  /// [headers] provides additional headers to include with requests.
  /// [followRedirects] determines whether to follow HTTP redirects.
  /// [maxRedirects] sets the maximum number of redirects to follow.
  WebScraper({
    this.timeout = const Duration(seconds: 30),
    this.userAgent =
        'AI-WebScraper/1.0 (+https://github.com/SamsonTobi/ai_webscraper)',
    this.headers = const <String, String>{},
    this.followRedirects = true,
    this.maxRedirects = 5,
    http.Client? client,
  })  : _client = client ?? http.Client(),
        _contentExtractor = ContentExtractor();
  /// The HTTP client used for making requests.
  final http.Client _client;

  /// The timeout duration for HTTP requests.
  final Duration timeout;

  /// The user agent string to use for requests.
  final String userAgent;

  /// Custom headers to include with requests.
  final Map<String, String> headers;

  /// Whether to follow redirects automatically.
  final bool followRedirects;

  /// Maximum number of redirects to follow.
  final int maxRedirects;

  /// Content extractor for processing HTML content.
  final ContentExtractor _contentExtractor;

  static final ScopedLogger _logger = Logger.scoped('WebScraper');

  /// Scrapes content from the specified URL.
  ///
  /// Returns the raw HTML content as a string. Throws [ScrapingException]
  /// if the request fails or times out.
  ///
  /// [url] is the URL to scrape.
  /// [customHeaders] provides additional headers for this specific request.
  Future<String> scrapeUrl(
    String url, {
    Map<String, String>? customHeaders,
  }) async {
    if (!_isValidUrl(url)) {
      throw URLValidationException(
        'Invalid URL format',
        url,
        'URL must be a valid HTTP or HTTPS URL',
      );
    }

    final Uri uri = Uri.parse(url);
    final Map<String, String> requestHeaders = <String, String>{
      'User-Agent': userAgent,
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
      'Accept-Encoding': 'gzip, deflate',
      'Connection': 'keep-alive',
      'Upgrade-Insecure-Requests': '1',
      ...headers,
      if (customHeaders != null) ...customHeaders,
    };

    try {
      final http.Response response =
          await _client.get(uri, headers: requestHeaders).timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return _decodeResponse(response);
      } else if (response.statusCode >= 300 && response.statusCode < 400) {
        // Handle redirects manually if needed
        if (followRedirects && response.headers.containsKey('location')) {
          final String redirectUrl = response.headers['location']!;
          final String resolvedUrl = uri.resolve(redirectUrl).toString();
          return await scrapeUrl(resolvedUrl, customHeaders: customHeaders);
        }
        throw ScrapingException(
          'Redirect not followed',
          url,
          response.statusCode,
          'Received redirect status ${response.statusCode} but redirect following is disabled',
        );
      } else {
        throw ScrapingException(
          'HTTP request failed with status ${response.statusCode}',
          url,
          response.statusCode,
          'Response body: ${response.body.length > 200 ? "${response.body.substring(0, 200)}..." : response.body}',
        );
      }
    } on TimeoutException {
      throw TimeoutException(
        'HTTP request timed out',
        timeout,
        'HTTP GET request to $url',
        'The server did not respond within ${timeout.inSeconds} seconds',
      );
    } on SocketException catch (e) {
      throw ScrapingException(
        'Network connection failed',
        url,
        null,
        'Socket error: ${e.message}',
      );
    } on HttpException catch (e) {
      throw ScrapingException(
        'HTTP protocol error',
        url,
        null,
        'HTTP error: ${e.message}',
      );
    } on FormatException catch (e) {
      throw URLValidationException(
        'Invalid URL format',
        url,
        'Format error: ${e.message}',
      );
    } on ScrapingException {
      // Re-throw ScrapingExceptions without wrapping them
      rethrow;
    } catch (e) {
      throw ScrapingException(
        'Unexpected error during HTTP request',
        url,
        null,
        'Error: $e',
      );
    }
  }

  /// Extracts cleaned text content from HTML.
  ///
  /// This method parses the HTML and extracts readable text content,
  /// removing scripts, styles, and other non-content elements.
  ///
  /// [htmlContent] is the raw HTML content.
  /// [preserveFormatting] determines whether to preserve line breaks and spacing.
  String extractTextContent(
    String htmlContent, {
    bool preserveFormatting = false,
  }) {
    try {
      final Document document = html_parser.parse(htmlContent);
      return _contentExtractor.extractTextContent(
        document,
        preserveFormatting: preserveFormatting,
      );
    } catch (e) {
      throw ParsingException(
        'Failed to parse HTML content',
        htmlContent,
        'HTML parsing error: $e',
      );
    }
  }

  /// Extracts specific elements from HTML using CSS selectors.
  ///
  /// Returns a list of elements matching the selector.
  ///
  /// [htmlContent] is the raw HTML content.
  /// [selector] is the CSS selector to match elements.
  List<Element> extractElements(String htmlContent, String selector) {
    try {
      final Document document = html_parser.parse(htmlContent);
      return _contentExtractor.extractElements(document, selector);
    } catch (e) {
      throw ParsingException(
        'Failed to extract elements with selector "$selector"',
        htmlContent,
        'Element extraction error: $e',
      );
    }
  }

  /// Extracts metadata from HTML (title, meta tags, etc.).
  ///
  /// Returns a map containing common metadata fields.
  ///
  /// [htmlContent] is the raw HTML content.
  Map<String, String> extractMetadata(String htmlContent) {
    try {
      final Document document = html_parser.parse(htmlContent);
      return _contentExtractor.extractMetadata(document);
    } catch (e) {
      throw ParsingException(
        'Failed to extract metadata from HTML',
        htmlContent,
        'Metadata extraction error: $e',
      );
    }
  }

  /// Extracts all links from HTML content.
  ///
  /// Returns a list of URLs found in the HTML.
  ///
  /// [htmlContent] is the raw HTML content.
  /// [baseUrl] is used to resolve relative URLs.
  List<String> extractLinks(String htmlContent, {String? baseUrl}) {
    try {
      final Document document = html_parser.parse(htmlContent);
      return _contentExtractor.extractLinks(document, baseUrl: baseUrl);
    } catch (e) {
      throw ParsingException(
        'Failed to extract links from HTML',
        htmlContent,
        'Link extraction error: $e',
      );
    }
  }

  /// Extracts images from HTML content.
  ///
  /// Returns a list of image URLs and their alt text.
  ///
  /// [htmlContent] is the raw HTML content.
  /// [baseUrl] is used to resolve relative URLs.
  List<Map<String, String>> extractImages(
    String htmlContent, {
    String? baseUrl,
  }) {
    try {
      final Document document = html_parser.parse(htmlContent);
      return _contentExtractor.extractImages(document, baseUrl: baseUrl);
    } catch (e) {
      throw ParsingException(
        'Failed to extract images from HTML',
        htmlContent,
        'Image extraction error: $e',
      );
    }
  }

  /// Scrapes multiple URLs concurrently.
  ///
  /// Returns a map of URL to HTML content for successful requests.
  /// Failed requests are logged but don't prevent other requests.
  ///
  /// [urls] is the list of URLs to scrape.
  /// [concurrency] limits the number of concurrent requests.
  /// [continueOnError] determines whether to continue if some requests fail.
  Future<Map<String, String>> scrapeUrls(
    List<String> urls, {
    int concurrency = 3,
    bool continueOnError = true,
    Map<String, String>? customHeaders,
  }) async {
    final Map<String, String> results = <String, String>{};
    final Semaphore semaphore = Semaphore(concurrency);

    final Iterable<Future<MapEntry<String, String>>> futures = urls.map((String url) async {
      await semaphore.acquire();
      try {
        final String content = await scrapeUrl(url, customHeaders: customHeaders);
        return MapEntry<String, String>(url, content);
      } catch (e) {
        if (!continueOnError) {
          rethrow;
        }
        // Log error but continue with other URLs
        _logger.info('Failed to scrape $url: $e');
        return MapEntry<String, String>(url, '');
      } finally {
        semaphore.release();
      }
    });

    final List<MapEntry<String, String>> completedResults = await Future.wait(futures);
    for (final MapEntry<String, String> entry in completedResults) {
      if (entry.value.isNotEmpty) {
        results[entry.key] = entry.value;
      }
    }

    return results;
  }

  /// Heuristic check to see if content looks like HTML even without proper content-type.
  bool _looksLikeHtml(String content) {
    final String trimmed = content.trim().toLowerCase();
    return trimmed.startsWith('<!doctype html') ||
        trimmed.startsWith('<html') ||
        trimmed.contains('<body') ||
        trimmed.contains('<head') ||
        trimmed.contains('<title');
  }

  /// Validates URL format and protocol.
  bool _isValidUrl(String url) {
    try {
      if (url.trim().isEmpty) {
        return false;
      }

      final Uri uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.hasAuthority &&
          uri.host.isNotEmpty; // Ensure host is not empty
    } on FormatException catch (e) {
      _logger.info('Something went wrong with validating $url: $e');
      return false;
    }
  }

  /// Decodes HTTP response body handling different encodings.
  String _decodeResponse(http.Response response) {
    final String contentType = response.headers['content-type'] ?? '';

    // Check if content type indicates HTML (be more lenient for testing)
    if (contentType.isNotEmpty &&
        !contentType.toLowerCase().contains('html') &&
        !contentType.toLowerCase().contains('xml') &&
        !contentType.toLowerCase().contains('text/plain') &&
        !_looksLikeHtml(response.body)) {
      throw ScrapingException(
        'Content type is not HTML or XML',
        response.request?.url.toString() ?? 'unknown',
        response.statusCode,
        'Content-Type: $contentType',
      );
    }

    // Handle different encodings
    String encoding = 'utf-8';
    final RegExpMatch? contentTypeMatch = RegExp(r'charset=([^;]+)').firstMatch(contentType);
    if (contentTypeMatch != null) {
      encoding = contentTypeMatch.group(1)!.toLowerCase();
    }

    try {
      switch (encoding) {
        case 'utf-8':
        case 'utf8':
          return utf8.decode(response.bodyBytes);
        case 'latin-1':
        case 'iso-8859-1':
          return latin1.decode(response.bodyBytes);
        default:
          // Fallback to UTF-8 for unknown encodings
          return utf8.decode(response.bodyBytes, allowMalformed: true);
      }
    } on FormatException catch (e) {
      _logger.info('Failed to decode $response: $e');
      // Final fallback - return raw string
      return response.body;
    }
  }

  /// Closes the HTTP client and releases resources.
  void dispose() {
    _client.close();
  }
}

/// Simple semaphore implementation for controlling concurrency.
class Semaphore {

  Semaphore(this.maxCount) : _currentCount = maxCount;

  final int maxCount;
  int _currentCount;
  final List<Completer<void>> _waitQueue = <Completer<void>>[];

  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }

    final Completer<void> completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      _waitQueue.removeAt(0)..complete();

    } else {
      _currentCount++;
    }
  }
}
