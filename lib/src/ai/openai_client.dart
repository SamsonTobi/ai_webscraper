import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../core/exceptions.dart';
import 'ai_client_base.dart';
import 'prompt_builder.dart';

/// OpenAI API client for content extraction using GPT models.
///
/// This client handles communication with OpenAI's Chat Completions API
/// to extract structured data from HTML content.
class OpenAIClient extends AIClientBase {
  /// The base URL for OpenAI API endpoints.
  static const String _baseUrl = 'https://api.openai.com/v1';

  /// The HTTP client used for API requests.
  final http.Client _httpClient;

  /// The GPT model to use for completions.
  final String model;

  /// Additional options for the OpenAI client.
  final Map<String, dynamic>? options;

  /// Creates an OpenAI client instance.
  OpenAIClient({
    required super.apiKey,
    required this.model,
    super.timeout,
    this.options,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

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
    try {
      // Validate inputs
      PromptBuilder.validateSchema(schema);

      // Build the chat prompt
      final messages = PromptBuilder.buildChatPrompt(
        htmlContent: htmlContent,
        schema: schema,
        instructions: options?['instructions'] as String?,
        maxLength: maxContentLength,
      );

      // Prepare the request
      final requestBody = _buildRequestBody(messages, options);
      final response = await _makeRequest(requestBody);

      // Parse and return the response
      return _parseResponse(response);
    } on AIClientException {
      rethrow;
    } catch (e) {
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
    final body = {
      'model': model,
      'messages': messages,
      'response_format': {'type': 'json_object'},
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
    final uri = Uri.parse('$_baseUrl/chat/completions');

    try {
      final response = await _httpClient
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
    return {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
      'User-Agent': 'ai_webscraper/1.0.0',
    };
  }

  /// Handles the HTTP response from the OpenAI API.
  Map<String, dynamic> _handleResponse(http.Response response) {
    final responseData = _parseJsonResponse(response.body);

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
        final error = responseData['error'] as Map<String, dynamic>?;
        final message = error?['message'] ?? 'Rate limit exceeded';
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
        final error = responseData['error'] as Map<String, dynamic>?;
        final message = error?['message'] ?? 'Unknown error';
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
      final choices = response['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw AIClientException(
          'No choices returned in OpenAI response',
          providerName,
        );
      }

      final firstChoice = choices[0] as Map<String, dynamic>;
      final message = firstChoice['message'] as Map<String, dynamic>?;

      if (message == null) {
        throw AIClientException(
          'No message found in OpenAI response choice',
          providerName,
        );
      }

      final content = message['content'] as String?;
      if (content == null || content.trim().isEmpty) {
        throw AIClientException(
          'Empty content in OpenAI response',
          providerName,
        );
      }

      // Parse the JSON content
      try {
        return jsonDecode(content.trim()) as Map<String, dynamic>;
      } catch (e) {
        throw ParsingException(
          'Failed to parse OpenAI response content as JSON: $e',
          content,
        );
      }
    } catch (e) {
      if (e is AIClientException || e is ParsingException) {
        rethrow;
      }
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
