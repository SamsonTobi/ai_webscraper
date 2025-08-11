import 'ai_provider.dart';

/// Represents the result of a web scraping operation.
///
/// This class encapsulates all information about a scraping attempt,
/// including whether it was successful, the extracted data, any errors,
/// and metadata about the operation.
class ScrapingResult {
  /// Creates a new scraping result.
  ///
  /// [success] indicates whether the operation was successful.
  /// [data] contains the extracted data (null if failed).
  /// [error] contains error details (null if successful).
  /// [scrapingTime] is the duration of the operation.
  /// [aiProvider] is the AI provider used.
  /// [url] is the URL that was scraped.
  /// [timestamp] is when the operation started (defaults to now).
  ScrapingResult({
    required this.success,
    this.data,
    this.error,
    required this.scrapingTime,
    required this.aiProvider,
    required this.url,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates a scraping result from a JSON map.
  ///
  /// This is useful for deserializing stored results.
  factory ScrapingResult.fromJson(Map<String, dynamic> json) {
    return ScrapingResult(
      success: json['success'] as bool,
      data: json['data'] as Map<String, dynamic>?,
      error: json['error'] as String?,
      scrapingTime: Duration(milliseconds: json['scrapingTimeMs'] as int),
      aiProvider: AIProvider.values.firstWhere(
        (AIProvider provider) => provider.name == json['aiProvider'],
      ),
      url: json['url'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Creates a failed scraping result.
  ///
  /// This is a convenience constructor for creating failed results.
  factory ScrapingResult.failure({
    required String error,
    required Duration scrapingTime,
    required AIProvider aiProvider,
    required String url,
    DateTime? timestamp,
  }) {
    return ScrapingResult(
      success: false,
      error: error,
      scrapingTime: scrapingTime,
      aiProvider: aiProvider,
      url: url,
      timestamp: timestamp,
    );
  }

  /// Creates a successful scraping result.
  ///
  /// This is a convenience constructor for creating successful results.
  factory ScrapingResult.success({
    required Map<String, dynamic> data,
    required Duration scrapingTime,
    required AIProvider aiProvider,
    required String url,
    DateTime? timestamp,
  }) {
    return ScrapingResult(
      success: true,
      data: data,
      scrapingTime: scrapingTime,
      aiProvider: aiProvider,
      url: url,
      timestamp: timestamp,
    );
  }

  /// Whether the scraping operation was successful.
  final bool success;

  /// The extracted data as a map of key-value pairs.
  ///
  /// This contains the structured data extracted according to the
  /// provided schema. Will be null if the operation failed.
  final Map<String, dynamic>? data;

  /// The error message if the operation failed.
  ///
  /// This contains details about what went wrong during scraping.
  /// Will be null if the operation was successful.
  final String? error;

  /// The time it took to complete the scraping operation.
  ///
  /// This includes both the web scraping time and AI processing time.
  final Duration scrapingTime;

  /// The AI provider used for data extraction.
  final AIProvider aiProvider;

  /// The URL that was scraped.
  final String url;

  /// The timestamp when the scraping operation started.
  final DateTime timestamp;

  /// Whether the result contains valid extracted data.
  ///
  /// Returns true if the operation was successful and data is not empty.
  bool get hasData => success && data != null && data!.isNotEmpty;

  /// Whether the result contains an error.
  ///
  /// Returns true if the operation failed and has an error message.
  bool get hasError => !success && error != null;

  /// The number of fields extracted from the data.
  ///
  /// Returns 0 if no data was extracted.
  int get fieldCount => data?.length ?? 0;

  /// Returns a list of all extracted field names.
  ///
  /// Returns an empty list if no data was extracted.
  List<String> get fieldNames => data?.keys.toList() ?? <String>[];

  /// Gets the value of a specific field from the extracted data.
  ///
  /// Returns null if the field doesn't exist or no data was extracted.
  T? getField<T>(String fieldName) {
    if (data == null) {
      return null;
    }
    // ignore: always_specify_types
    final value = data![fieldName];
    return value is T ? value : null;
  }

  /// Creates a copy of this result with updated values.
  ///
  /// This allows you to create a new result based on an existing one
  /// with some fields modified.
  ScrapingResult copyWith({
    bool? success,
    Map<String, dynamic>? data,
    String? error,
    Duration? scrapingTime,
    AIProvider? aiProvider,
    String? url,
    DateTime? timestamp,
  }) {
    return ScrapingResult(
      success: success ?? this.success,
      data: data ?? this.data,
      error: error ?? this.error,
      scrapingTime: scrapingTime ?? this.scrapingTime,
      aiProvider: aiProvider ?? this.aiProvider,
      url: url ?? this.url,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Converts the result to a JSON-serializable map.
  ///
  /// This includes comprehensive information suitable for API responses.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'success': success,
      'data': data,
      'error': error,
      'metadata': <String, dynamic>{
        'scrapingTimeMs': scrapingTime.inMilliseconds,
        'aiProvider': aiProvider.displayName,
        'providerCode': aiProvider.name,
        'url': url,
        'timestamp': timestamp.toIso8601String(),
        'fieldCount': fieldCount,
        'fieldNames': fieldNames,
        'hasData': hasData,
        'hasError': hasError,
      },
    };
  }

  @override
  String toString() {
    if (success) {
      return 'ScrapingResult(success: true, url: $url, provider: ${aiProvider.displayName}, '
          'fields: $fieldCount, time: ${scrapingTime.inMilliseconds}ms)';
    } else {
      return 'ScrapingResult(success: false, url: $url, provider: ${aiProvider.displayName}, '
          'error: $error, time: ${scrapingTime.inMilliseconds}ms)';
    }
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! ScrapingResult) {
      return false;
    }

    return success == other.success &&
        data.toString() == other.data.toString() &&
        error == other.error &&
        scrapingTime == other.scrapingTime &&
        aiProvider == other.aiProvider &&
        url == other.url &&
        timestamp == other.timestamp;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode {
    return Object.hash(
      success,
      data,
      error,
      scrapingTime,
      aiProvider,
      url,
      timestamp,
    );
  }
}
