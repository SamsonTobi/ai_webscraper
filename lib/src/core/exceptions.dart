/// Base exception class for all AI WebScraper related exceptions.
///
/// This serves as the parent class for all custom exceptions thrown
/// by the AI WebScraper package.
abstract class AIWebScraperException implements Exception {

  /// Creates a new AI WebScraper exception.
  const AIWebScraperException(this.message, [this.context]);
  /// The error message describing what went wrong.
  final String message;

  /// Optional additional context about the error.
  final String? context;

  @override
  String toString() {
    if (context != null) {
      return '$runtimeType: $message\nContext: $context';
    }
    return '$runtimeType: $message';
  }
}

/// Exception thrown when schema validation fails.
///
/// This exception is thrown when the provided schema is invalid,
/// malformed, or contains unsupported field types.
class SchemaValidationException extends AIWebScraperException {
  /// Creates a new schema validation exception.
  const SchemaValidationException(super.message, [super.context]);
}

/// Exception thrown when URL validation fails.
///
/// This exception is thrown when the provided URL is invalid,
/// malformed, or uses an unsupported protocol.
class URLValidationException extends AIWebScraperException {

  /// Creates a new URL validation exception.
  const URLValidationException(super.message, this.url, [super.context]);
  /// The invalid URL that caused the exception.
  final String url;

  @override
  String toString() {
    final String baseString = super.toString();
    return '$baseString\nInvalid URL: $url';
  }
}

/// Exception thrown when web scraping fails.
///
/// This exception is thrown when the web scraping operation fails
/// due to network issues, timeout, or other HTTP-related problems.
class ScrapingException extends AIWebScraperException {

  /// Creates a new scraping exception.
  const ScrapingException(
    super.message,
    this.url, [
    this.statusCode,
    super.context,
  ]);
  /// The URL that failed to be scraped.
  final String url;

  /// The HTTP status code, if available.
  final int? statusCode;

  @override
  String toString() {
    final String baseString = super.toString();
    final String statusInfo = statusCode != null ? ' (Status: $statusCode)' : '';
    return '$baseString\nFailed URL: $url$statusInfo';
  }
}

/// Exception thrown when AI provider operations fail.
///
/// This exception is thrown when the AI provider API call fails
/// due to authentication, rate limiting, or service unavailability.
class AIProviderException extends AIWebScraperException {

  /// Creates a new AI provider exception.
  const AIProviderException(
    super.message,
    this.provider, [
    this.statusCode,
    super.context,
  ]);
  /// The AI provider that caused the exception.
  final String provider;

  /// The HTTP status code from the AI provider, if available.
  final int? statusCode;

  @override
  String toString() {
    final String baseString = super.toString();
    final String statusInfo = statusCode != null ? ' (Status: $statusCode)' : '';
    return '$baseString\nProvider: $provider$statusInfo';
  }
}

/// Exception thrown when data parsing fails.
///
/// This exception is thrown when the AI provider returns data
/// that cannot be parsed as valid JSON or doesn't match the expected format.
class ParsingException extends AIWebScraperException {

  /// Creates a new parsing exception.
  const ParsingException(super.message, this.rawData, [super.context]);
  /// The raw data that failed to parse.
  final String rawData;

  @override
  String toString() {
    final String baseString = super.toString();
    final String truncatedData =
        rawData.length > 200 ? '${rawData.substring(0, 200)}...' : rawData;
    return '$baseString\nRaw data: $truncatedData';
  }
}

/// Exception thrown when timeout occurs.
///
/// This exception is thrown when an operation exceeds the configured
/// timeout duration.
class TimeoutException extends AIWebScraperException {

  /// Creates a new timeout exception.
  const TimeoutException(
    super.message,
    this.timeout,
    this.operation, [
    super.context,
  ]);
  /// The timeout duration that was exceeded.
  final Duration timeout;

  /// The operation that timed out.
  final String operation;

  @override
  String toString() {
    final String baseString = super.toString();
    return '$baseString\nOperation: $operation\nTimeout: ${timeout.inSeconds}s';
  }
}

/// Exception thrown when batch processing fails.
///
/// This exception is thrown when batch processing encounters
/// critical errors that prevent further processing.
class BatchProcessingException extends AIWebScraperException {

  /// Creates a new batch processing exception.
  const BatchProcessingException(
    super.message,
    this.successCount,
    this.totalCount, [
    super.context,
  ]);
  /// The number of URLs that were successfully processed.
  final int successCount;

  /// The total number of URLs in the batch.
  final int totalCount;

  @override
  String toString() {
    final String baseString = super.toString();
    return '$baseString\nProcessed: $successCount/$totalCount';
  }
}

/// Exception thrown when JavaScript scraping fails.
///
/// This exception is thrown when Puppeteer or JavaScript rendering
/// encounters errors during dynamic content loading.
class JavaScriptScrapingException extends AIWebScraperException {

  /// Creates a new JavaScript scraping exception.
  const JavaScriptScrapingException(super.message, this.url, [super.context]);
  /// The URL that failed JavaScript scraping.
  final String url;

  @override
  String toString() {
    final String baseString = super.toString();
    return '$baseString\nFailed URL: $url';
  }
}

/// Exception thrown when an unsupported AI provider is requested.
///
/// This exception is thrown when trying to create a client for
/// an AI provider that is not implemented or supported.
class UnsupportedProviderException extends AIWebScraperException {
  /// Creates a new unsupported provider exception.
  const UnsupportedProviderException(super.message, [super.context]);
}

/// Exception thrown when API key validation fails.
///
/// This exception is thrown when the provided API key is invalid,
/// malformed, or doesn't match the expected format for the provider.
class InvalidApiKeyException extends AIWebScraperException {
  /// Creates a new invalid API key exception.
  const InvalidApiKeyException(super.message, [super.context]);
}

/// Exception thrown when AI client operations fail.
///
/// This is a specific type of AI provider exception for client-level errors.
class AIClientException extends AIProviderException {
  /// Creates a new AI client exception.
  const AIClientException(
    super.message,
    super.provider, [
    super.statusCode,
    super.context,
  ]);
}
