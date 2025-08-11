import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/exceptions.dart';
import '../utils/logger.dart';
import '../utils/response_cache.dart';
import 'ai_client_base.dart';
import 'prompt_builder.dart';

/// OpenAI API client for content extraction using GPT models.
///
/// This client handles communication with OpenAI's Chat Completions API
/// to extract structured data from HTML content.
class OpenAIClient extends AIClientBase {

  /// Creates an OpenAI client instance.
  OpenAIClient({
    required super.apiKey,
    required this.model,
    super.timeout,
    this.options,
    http.Client? httpClient,
    ResponseCache? cache,
  })  : _httpClient = httpClient ?? http.Client(),
        _cache = cache;
  /// The base URL for OpenAI API endpoints.
  static const String _baseUrl = 'https://api.openai.com/v1';

  /// The HTTP client used for API requests.
  final http.Client _httpClient;

  /// The GPT model to use for completions.
  final String model;

  /// Additional options for the OpenAI client.
  final Map<String, dynamic>? options;

  /// Response cache for storing AI responses.
  final ResponseCache? _cache;

  /// Logger for this client.
  static final ScopedLogger _logger = Logger.scoped('OpenAIClient');

  @override
  String get providerName => 'OpenAI';

  @override
  int get maxContentLength => 50000; // Conservative estimate for token limits

  @override
  bool validateApiKey() {
    // OpenAI API keys typically start with 'sk-' and are 51 characters long
    return apiKey.startsWith('sk-') && apiKey.length >= 20;
  }

  @override
  Future<Map<String, dynamic>> extractData({
    required String htmlContent,
    required Map<String, String> schema,
    Map<String, dynamic>? options,
  }) async {
    _logger..info('Starting data extraction with OpenAI')
    ..debug('Schema: $schema')
    ..debug('HTML content length: ${htmlContent.length} characters');

    // Check cache first
    if (_cache != null) {
      final CacheEntry? cachedEntry = _cache!.get(
        htmlContent: htmlContent,
        schema: schema,
        provider: providerName,
        options: options,
      );

      if (cachedEntry != null) {
        _logger..info('Using cached response for data extraction')
        ..debug('Cached raw response: ${cachedEntry.rawResponse}');
        return cachedEntry.data;
      }
    }

    try {
      // Validate inputs
      PromptBuilder.validateSchema(schema);

      // Build the chat prompt
      final List<Map<String, String>> messages = PromptBuilder.buildChatPrompt(
        htmlContent: htmlContent,
        schema: schema,
        instructions: options?['instructions'] as String?,
        maxLength: maxContentLength,
      );

      _logger.debug('Generated ${messages.length} messages for OpenAI');

      // Prepare the request
      final Map<String, dynamic> requestBody = _buildRequestBody(messages, options);
      _logger
          .debug('Request body prepared with model: ${requestBody['model']}');

      final Map<String, dynamic> response = await _makeRequest(requestBody);

      // Log the raw response
      final String rawResponse = jsonEncode(response);
      _logger..info('Received response from OpenAI API')
      ..info('=== RAW OPENAI RESPONSE START ===')
      ..info(rawResponse)
      ..info('=== RAW OPENAI RESPONSE END ===');

      // Parse and return the response
      final Map<String, dynamic> parsedData = _parseResponse(response);
      _logger..info('Successfully parsed OpenAI response')
      ..debug('Parsed data keys: ${parsedData.keys.toList()}');

      // Store in cache if available
      if (_cache != null) {
        await _cache!.store(
          htmlContent: htmlContent,
          schema: schema,
          provider: providerName,
          rawResponse: rawResponse,
          parsedData: parsedData,
          options: options,
        );
        _logger.debug('Stored response in cache');
      }

      return parsedData;
    } on AIClientException {
      rethrow;
    } catch (e) {
      _logger.error('Failed to extract data using OpenAI', e);
      throw AIClientException(
        'Failed to extract data using OpenAI: $e',
        providerName,
      );
    }
  }

  /// Builds the request body for the OpenAI API call.
  Map<String, dynamic> _buildRequestBody(
    List<Map<String, String>> messages,
    Map<String, dynamic>? options,
  ) {
    final Map<String, dynamic> body = <String, dynamic>{
      'model': model,
      'messages': messages,
      'response_format': <String, String>{'type': 'json_object'},
      'temperature': options?['temperature'] ?? 0.1,
      'max_tokens': options?['max_tokens'] ?? 1000,
    };

    // Add optional parameters if provided
    if (options?['top_p'] != null) {
      body['top_p'] = options!['top_p'];
    }
    if (options?['frequency_penalty'] != null) {
      body['frequency_penalty'] = options!['frequency_penalty'];
    }
    if (options?['presence_penalty'] != null) {
      body['presence_penalty'] = options!['presence_penalty'];
    }

    return body;
  }

  /// Makes the HTTP request to the OpenAI API.
  Future<Map<String, dynamic>> _makeRequest(Map<String, dynamic> body) async {
    final Uri uri = Uri.parse('$_baseUrl/chat/completions');

    try {
      final http.Response response = await _httpClient
          .post(
            uri,
            headers: _buildHeaders(),
            body: jsonEncode(body),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } on SocketException {
      throw AIClientException(
        'Network error: Unable to connect to OpenAI API',
        providerName,
      );
    } on TimeoutException {
      throw AIClientException(
        'Request timed out after ${timeout.inSeconds} seconds',
        providerName,
      );
    } on http.ClientException catch (e) {
      throw AIClientException(
        'HTTP client error: $e',
        providerName,
      );
    }
  }

  /// Builds the HTTP headers for API requests.
  Map<String, String> _buildHeaders() {
    return <String, String>{
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'User-Agent': 'ai_webscraper/1.0.0',
    };
  }

  /// Handles the HTTP response from the OpenAI API.
  Map<String, dynamic> _handleResponse(http.Response response) {
    final Map<String, dynamic> responseData = _parseJsonResponse(response.body);

    switch (response.statusCode) {
      case 200:
        return responseData;

      case 401:
        throw AIClientException(
          'Authentication failed: Invalid API key',
          providerName,
          401,
        );

      case 403:
        throw AIClientException(
          'Access forbidden: Check your API key permissions',
          providerName,
          403,
        );

      case 429:
        final Map<String, dynamic>? error = responseData['error'] as Map<String, dynamic>?;
        final dynamic message = error?['message'] ?? 'Rate limit exceeded';
        throw AIClientException(
          'Rate limit exceeded: $message',
          providerName,
          429,
        );

      case 500:
      case 502:
      case 503:
      case 504:
        throw AIClientException(
          'OpenAI service unavailable (${response.statusCode})',
          providerName,
          response.statusCode,
        );

      default:
        final Map<String, dynamic>? error = responseData['error'] as Map<String, dynamic>?;
        final dynamic message = error?['message'] ?? 'Unknown error';
        throw AIClientException(
          'OpenAI API error (${response.statusCode}): $message',
          providerName,
          response.statusCode,
        );
    }
  }

  /// Parses the JSON response body.
  Map<String, dynamic> _parseJsonResponse(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      throw AIClientException(
        'Failed to parse OpenAI response as JSON: $e',
        providerName,
      );
    }
  }

  /// Parses the OpenAI response and extracts the generated content.
  Map<String, dynamic> _parseResponse(Map<String, dynamic> response) {
    try {
      final List<dynamic> choices = response['choices'] as List<dynamic>;
      if (choices.isEmpty) {
        _logger.error('No choices returned in OpenAI response');
        throw AIClientException(
          'No choices returned in OpenAI response',
          providerName,
        );
      }

      final Map<String, dynamic> firstChoice = choices[0] as Map<String, dynamic>;
      final Map<String, dynamic>? message = firstChoice['message'] as Map<String, dynamic>?;

      if (message == null) {
        _logger.error('No message found in OpenAI response choice');
        throw AIClientException(
          'No message found in OpenAI response choice',
          providerName,
        );
      }

      final String? content = message['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        _logger.error('Empty content in OpenAI response');
        throw AIClientException(
          'Empty content in OpenAI response',
          providerName,
        );
      }

      _logger.debug('Response content length: ${content.length} characters');

      // Parse the JSON content
      try {
        final Map<String, dynamic> parsed = jsonDecode(content.trim()) as Map<String, dynamic>;
        _logger.debug('Successfully parsed OpenAI response as JSON');
        return parsed;
      } catch (e) {
        _logger..error('Failed to parse OpenAI response content as JSON: $e')
        ..info('=== PROBLEMATIC OPENAI CONTENT START ===')
        ..info(content)
        ..info('=== PROBLEMATIC OPENAI CONTENT END ===');
        throw ParsingException(
          'Failed to parse OpenAI response content as JSON: $e',
          content,
        );
      }
    } catch (e) {
      if (e is AIClientException || e is ParsingException) {
        rethrow;
      }
      _logger.error('Unexpected response structure from OpenAI', e);
      throw AIClientException(
        'Unexpected response structure from OpenAI: $e',
        providerName,
      );
    }
  }

  /// Disposes of resources used by this client.
  void dispose() {
    _httpClient.close();
  }
}
