import 'dart:async';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../core/exceptions.dart';
import 'ai_client_base.dart';
import 'prompt_builder.dart';

/// Google Gemini API client for content extraction.
///
/// This client handles communication with Google's Gemini API
/// to extract structured data from HTML content.
class GeminiClient extends AIClientBase {
  /// The Gemini generative model instance.
  late final GenerativeModel _model;

  /// The model name to use for generation.
  final String model;

  /// Additional options for the Gemini client.
  final Map<String, dynamic>? options;

  /// Creates a Gemini client instance.
  GeminiClient({
    required super.apiKey,
    required this.model,
    super.timeout,
    this.options,
  }) {
    _initializeModel();
  }

  @override
  String get providerName => 'Gemini';

  @override
  int get maxContentLength => 100000; // Gemini has higher content limits

  @override
  bool validateApiKey() {
    // Gemini API keys are typically 39 characters long and start with 'AI'
    // But we accept shorter test keys as long as they're at least 10 chars
    return apiKey.startsWith('AI') && apiKey.length >= 10;
  }

  /// Initializes the Gemini generative model.
  void _initializeModel() {
    try {
      final GenerationConfig config = GenerationConfig(
        temperature: _parseDouble(options?['temperature']) ?? 0.1,
        topK: _parseInt(options?['top_k']),
        topP: _parseDouble(options?['top_p']),
        maxOutputTokens: _parseInt(options?['max_tokens']) ?? 1000,
        responseMimeType: 'application/json',
      );

      final List<SafetySetting> safetySettings = <SafetySetting>[
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ];

      _model = GenerativeModel(
        model: model,
        apiKey: apiKey,
        generationConfig: config,
        safetySettings: safetySettings,
      );
    } catch (e) {
      throw AIClientException(
        'Failed to initialize Gemini model: $e',
        providerName,
      );
    }
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

      // Build the prompt
      final String prompt = PromptBuilder.buildTextPrompt(
        htmlContent: htmlContent,
        schema: schema,
        instructions: options?['instructions'] as String?,
        maxLength: maxContentLength,
      );

      // Generate content
      final GenerateContentResponse response = await _generateContent(prompt);

      // Parse and return the response
      return _parseResponse(response);
    } on AIClientException {
      rethrow;
    } catch (e) {
      throw AIClientException(
        'Failed to extract data using Gemini: $e',
        providerName,
      );
    }
  }

  /// Generates content using the Gemini model.
  Future<GenerateContentResponse> _generateContent(String prompt) async {
    try {
      final Content content = Content.text(prompt);
      final GenerateContentResponse response =
          await _model.generateContent(<Content>[content]).timeout(timeout);

      return response;
    } on TimeoutException {
      throw AIClientException(
        'Request timed out after ${timeout.inSeconds} seconds',
        providerName,
      );
    } on GenerativeAIException catch (e) {
      throw _handleGeminiException(e);
    } catch (e) {
      throw AIClientException(
        'Unexpected error during Gemini generation: $e',
        providerName,
      );
    }
  }

  /// Handles Gemini-specific exceptions and converts them to AIClientExceptions.
  AIClientException _handleGeminiException(GenerativeAIException e) {
    final String message = e.message;

    // Check error message for common patterns
    if (message.toLowerCase().contains('api key')) {
      return AIClientException(
        'Invalid API key: $message',
        providerName,
        401,
      );
    }

    if (message.toLowerCase().contains('quota') ||
        message.toLowerCase().contains('rate limit')) {
      return AIClientException(
        'Quota exceeded: $message',
        providerName,
        429,
      );
    }

    if (message.toLowerCase().contains('blocked') ||
        message.toLowerCase().contains('safety')) {
      return AIClientException(
        'Content blocked by safety filters: $message',
        providerName,
        400,
      );
    }

    if (message.toLowerCase().contains('location') ||
        message.toLowerCase().contains('region')) {
      return AIClientException(
        'Unsupported user location: $message',
        providerName,
        403,
      );
    }

    // Default case
    return AIClientException(
      'Gemini API error: $message',
      providerName,
    );
  }

  /// Parses the Gemini response and extracts the generated content.
  Map<String, dynamic> _parseResponse(GenerateContentResponse response) {
    try {
      // Check if response has text
      if (response.text == null || response.text!.trim().isEmpty) {
        throw AIClientException(
          'Empty response from Gemini API',
          providerName,
        );
      }

      final String responseText = response.text!.trim();

      // Try to parse as JSON
      try {
        return jsonDecode(responseText) as Map<String, dynamic>;
      } catch (e) {
        // If direct parsing fails, try to extract JSON from the response
        final RegExpMatch? jsonMatch =
            RegExp(r'\{.*\}', dotAll: true).firstMatch(responseText);
        if (jsonMatch != null) {
          try {
            return jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
          // ignore: avoid_catches_without_on_clauses
          } catch (e) {
            // Still failed, throw parsing exception
          }
        }

        throw ParsingException(
          'Failed to parse Gemini response as JSON: $e',
          responseText,
        );
      }
    } catch (e) {
      if (e is AIClientException || e is ParsingException) {
        rethrow;
      }
      throw AIClientException(
        'Unexpected response structure from Gemini: $e',
        providerName,
      );
    }
  }

  /// Gets usage metadata from the last response, if available.
  UsageMetadata? getLastUsageMetadata(GenerateContentResponse response) {
    return response.usageMetadata;
  }

  /// Checks if the model supports the requested features.
  bool supportsJsonMode() {
    // Gemini 1.5 models support JSON mode
    return model.contains('1.5');
  }

  /// Helper method to safely parse a dynamic value to double.
  double? _parseDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  /// Helper method to safely parse a dynamic value to int.
  int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
