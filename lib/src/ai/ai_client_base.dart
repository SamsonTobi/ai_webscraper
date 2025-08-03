import 'dart:async';

/// Abstract base class for AI clients that handle content extraction.
///
/// This class defines the interface that all AI provider implementations
/// must follow, ensuring consistent behavior across different AI services.
abstract class AIClientBase {
  /// The API key used for authentication with the AI service.
  final String apiKey;

  /// The timeout duration for API requests.
  final Duration timeout;

  /// Creates an AI client with the specified configuration.
  AIClientBase({
    required this.apiKey,
    this.timeout = const Duration(seconds: 30),
  });

  /// Extracts structured data from HTML content using AI.
  ///
  /// Takes [htmlContent] and a [schema] definition that specifies
  /// what data to extract and in what format. Returns a map containing
  /// the extracted data matching the schema structure.
  ///
  /// Throws [AIClientException] if the AI service returns an error
  /// or if the response cannot be parsed.
  Future<Map<String, dynamic>> extractData({
    required String htmlContent,
    required Map<String, String> schema,
    Map<String, dynamic>? options,
  });

  /// Validates the API key format for the specific AI provider.
  ///
  /// Returns true if the API key appears to be in the correct format
  /// for this provider. This is a basic validation and doesn't guarantee
  /// the key is valid with the service.
  bool validateApiKey();

  /// Gets the provider-specific name for logging and identification.
  String get providerName;

  /// Gets the maximum content length supported by this AI provider.
  /// Returns null if there's no specific limit.
  int? get maxContentLength;
}
