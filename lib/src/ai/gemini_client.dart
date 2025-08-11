// ignore_for_file: strict_raw_type

import 'dart:async';
import 'dart:convert';

import 'package:ai_webscraper/src/core/exceptions.dart';
import 'package:ai_webscraper/src/utils/logger.dart';
import 'package:ai_webscraper/src/utils/response_cache.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'ai_client_base.dart';
import 'prompt_builder.dart';

/// Google Gemini API client for content extraction.
///
/// This client handles communication with Google's Gemini API
/// to extract structured data from HTML content.
class GeminiClient extends AIClientBase {

  // =====================================================================
  // Constructor
  // =====================================================================
  GeminiClient({
    required super.apiKey,
    required this.model,
    super.timeout,
    this.options,
    ResponseCache? cache,
  }) : _cache = cache {
    _initializeModel();
  }
  // =====================================================================
  // Fields
  // =====================================================================
  late final GenerativeModel _model;
  // ignore: public_member_api_docs
  final String model;
  // ignore: public_member_api_docs
  final Map<String, dynamic>? options;
  final ResponseCache? _cache;
  static final ScopedLogger _logger = Logger.scoped('GeminiClient');

  // =====================================================================
  // Base overrides
  // =====================================================================
  @override
  String get providerName => 'Gemini';

  @override
  int get maxContentLength => 100000;

  @override
  bool validateApiKey() => apiKey.startsWith('AI') && apiKey.length >= 10;

  // =====================================================================
  // Initialization
  // =====================================================================
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
    _logger..info('Starting data extraction with Gemini')
    ..debug('Schema: $schema')
    ..debug('HTML length: ${htmlContent.length}');

    // Cache lookup
    if (_cache != null) {
      final CacheEntry? cached = _cache!.get(
        htmlContent: htmlContent,
        schema: schema,
        provider: providerName,
        options: options,
      );
      if (cached != null) {
        _logger.info('Cache hit – returning cached data');
        return cached.data;
      }
    }

    try {
      // Basic validation only (ensures schema map not empty / key format)
      PromptBuilder.validateSchema(schema);

      // Build prompt (no schema text included!)
      final String prompt = _buildPromptForResponseSchema(
        htmlContent: htmlContent,
        instructions: options?['instructions'] as String?,
        maxLength: maxContentLength,
      );
      _logger..info('Prompt length: ${prompt.length}')
      ..info('=== HTML PREVIEW (≤1000 chars) ===')
      ..info(htmlContent.length > 1000
          ? '${htmlContent.substring(0, 1000)}...'
          : htmlContent)
      ..info('=== END HTML PREVIEW ===');

      // Model call with responseSchema enforcement
      final GenerateContentResponse response = await _generateContent(prompt, schema);

      final String raw = response.text ?? '';
      _logger..info('Received response from Gemini API')
      ..info('=== RAW GEMINI RESPONSE START ===')
      ..info(raw)
      ..info('=== RAW GEMINI RESPONSE END ===');

      final Map<String, dynamic> parsed = _parseResponse(response);
      final Map<String, dynamic> normalized = _normalizeParsedData(parsed, schema);
      _logger..info('Parsed & normalized Gemini response')
      ..debug('Final keys: ${normalized.keys.toList()}');

      if (_cache != null) {
        await _cache!.store(
          htmlContent: htmlContent,
          schema: schema,
          provider: providerName,
          rawResponse: raw,
          parsedData: normalized,
          options: options,
        );
      }
      return normalized;
    } on AIClientException {
      rethrow;
    } catch (e, st) {
      _logger.error('Gemini extraction failed', e, st);
      throw AIClientException(
        'Failed to extract data using Gemini: $e',
        providerName,
      );
    }
  }

  /// Generates content using the Gemini model.
  Future<GenerateContentResponse> _generateContent(
    String prompt,
    Map<String, String> schema,
  ) async {
    try {
      final Content content = Content.text(prompt);

      // Convert our schema to Gemini's Schema format
      final Schema responseSchema = _buildGeminiSchema(schema);
      _logger..info('Schema fields: ${schema.keys.toList()}')
      ..debug('Using response schema: $responseSchema');

      final GenerateContentResponse response = await _model.generateContent(
        <Content>[content],
        generationConfig: GenerationConfig(
          temperature: _parseDouble(options?['temperature']) ?? 0.1,
          topK: _parseInt(options?['top_k']),
          topP: _parseDouble(options?['top_p']),
          maxOutputTokens: _parseInt(options?['max_tokens']) ?? 1000,
          responseMimeType: 'application/json',
          responseSchema: responseSchema,
        ),
      ).timeout(timeout);

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

  /// Converts our simple schema format to Gemini's Schema format.
  Schema _buildGeminiSchema(Map<String, String> schema) {
    final Map<String, Schema> properties = <String, Schema>{};
    final List<String> required = <String>[]; // All fields will be required

    for (final MapEntry<String, String> entry in schema.entries) {
      final String fieldName = entry.key.trim();
      String fieldType = entry.value.trim().toLowerCase();

      // Remove ! suffix if present (we'll make all required anyway)
      if (fieldType.endsWith('!')) {
        fieldType = fieldType.substring(0, fieldType.length - 1);
      }

      // Make all fields required to ensure complete responses
      required.add(fieldName);
      properties[fieldName] = _schemaFromType(fieldType, fieldName);
    }

    _logger..debug('Schema properties: ${properties.keys.toList()}')
    ..debug('Required fields: $required');

    return Schema.object(
      properties: properties,
      requiredProperties: required, // All fields required
    );
  }

  /// Helper to convert a type string into a Gemini Schema.
  /// Supports:
  /// - primitive types: string, text, number, int/integer, float/double, boolean/bool, date, datetime, url, email
  /// - object (generic open object)
  // ignore: lines_longer_than_80_chars
  /// - arrays: array, list, array: string, array: number, array: boolean, array<object>
  Schema _schemaFromType(String rawType, String fieldName) {
    final String t = rawType.trim();

    // Typed arrays: array<type>
    final RegExpMatch? arrayMatch = RegExp(r'^array<([^>]+)>').firstMatch(t);
    if (arrayMatch != null) {
      final String inner = arrayMatch.group(1)!.trim();
      final Schema itemSchema = _schemaFromType(inner, '${fieldName}_item');
      _logger
          .debug('Configured typed array for $fieldName with item type $inner');
      return Schema.array(items: itemSchema);
    }

    // Generic array/list
    if (t == 'array' || t == 'list') {
      return Schema.array(items: Schema.string());
    }

    switch (t) {
      case 'string':
      case 'text':
        return Schema.string();
      case 'number':
      case 'float':
      case 'double':
        return Schema.number();
      case 'int':
      case 'integer':
        return Schema.integer();
      case 'boolean':
      case 'bool':
        return Schema.boolean();
      case 'date':
      case 'datetime':
        return Schema.string(description: 'Date in ISO 8601 format');
      case 'url':
        return Schema.string(description: 'Valid URL');
      case 'email':
        return Schema.string(description: 'Valid email address');
      case 'object':
        // For object types, use string and let the prompt instruct proper extraction
        // This avoids Gemini's requirement for non-empty object properties
        return Schema.string(
            description:
                'Complex object data as JSON string or structured text');
      default:
        _logger.warning('Unknown field type: $t (defaulting to string)');
        return Schema.string();
    }
  }

  /// Builds a prompt for use with responseSchema (without schema description).
  String _buildPromptForResponseSchema({
    required String htmlContent,
    String? instructions,
    int maxLength = 50000,
  }) {
    final String truncatedContent = _truncateContent(htmlContent, maxLength);
    final String customInstructions = instructions != null
        ? '\nAdditional Instructions (follow but do NOT restate schema):\n$instructions\n'
        : '';

    return '''
You are a professional web scraping assistant. Extract structured data from the HTML and return ONLY valid JSON.

Instructions:
1. Only output the JSON object (no markdown, no prose).
2. Use the response schema provided out-of-band (DO NOT restate it in text).
3. Extract ALL fields defined in the schema - return the complete structure.
4. Use real values from the HTML; never hallucinate.
5. If a value is absent: output null (unquoted). Never use the string "null", "N/A" or placeholders.
6. For arrays: list real items; if none, use []. Never include ["null"].
7. Preserve data types (string/number/boolean/array) exactly.
8. For object fields: extract structured content as a JSON string or formatted text.
9. Dates: prefer ISO 8601 if present; partial dates allowed if that's all that's available.
10. Do not invent URLs, emails or prices; use null if missing.
11. Trim surrounding whitespace.
12. Include ALL schema fields in the response, even if some are null.
$customInstructions
HTML CONTENT START
$truncatedContent
HTML CONTENT END

Return ONLY the complete JSON object with all schema fields now.
''';
  }

  /// Truncates HTML content to fit within token limits.
  String _truncateContent(String content, int maxLength) {
    if (content.length <= maxLength) {
      return content;
    }

    // Try to truncate at a reasonable boundary
    final String truncated = content.substring(0, maxLength);

    // Find the last complete HTML tag or sentence
    final int lastTagEnd = truncated.lastIndexOf('>');
    final int lastSentenceEnd = truncated.lastIndexOf('.');

    final int cutPoint =
        lastTagEnd > lastSentenceEnd ? lastTagEnd + 1 : lastSentenceEnd + 1;

    if (cutPoint > maxLength * 0.8) {
      return '${truncated.substring(0, cutPoint)}\n\n[Content truncated...]';
    } else {
      return '$truncated\n\n[Content truncated...]';
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
        _logger.error('Empty response from Gemini API');
        throw AIClientException(
          'Empty response from Gemini API',
          providerName,
        );
      }

      final String responseText = response.text!.trim();
      _logger.debug('Response text length: ${responseText.length} characters');

      // Try to parse as JSON
      try {
        final Map<String, dynamic> parsed = jsonDecode(responseText) as Map<String, dynamic>;
        _logger.debug('Successfully parsed response as JSON');
        return parsed;
      } catch (e) {
        _logger..warning(
            'Direct JSON parsing failed, attempting to extract JSON from response: $e')
        ..info('=== PROBLEMATIC RESPONSE TEXT START ===')
        ..info(responseText)
        ..info('=== PROBLEMATIC RESPONSE TEXT END ===');

        // If direct parsing fails, try to extract JSON from the response
        final RegExpMatch? jsonMatch =
            RegExp(r'\{.*\}', dotAll: true).firstMatch(responseText);
        if (jsonMatch != null) {
          final String extractedJson = jsonMatch.group(0)!;
          _logger..info('=== EXTRACTED JSON START ===')
          ..info(extractedJson)
          ..info('=== EXTRACTED JSON END ===');

          try {
            final Map<String, dynamic> extracted = jsonDecode(extractedJson) as Map<String, dynamic>;
            _logger.debug('Successfully extracted JSON from response');
            return extracted;
            // ignore: avoid_catches_without_on_clauses
          } catch (e) {
            // ignore: avoid_single_cascade_in_expression_statements
            _logger..error('Failed to parse extracted JSON: $e')
            ..error('Extracted JSON that failed to parse: $extractedJson');
            // Still failed, throw parsing exception
          }
        }

        _logger.error('No valid JSON found in response');
        throw ParsingException(
          'Failed to parse Gemini response as JSON: $e',
          responseText,
        );
      }
    } catch (e) {
      if (e is AIClientException || e is ParsingException) {
        rethrow;
      }
      _logger.error('Unexpected response structure from Gemini', e);
      throw AIClientException(
        'Unexpected response structure from Gemini: $e',
        providerName,
      );
    }
  }

  // =====================================================================
  // Normalization: clean string "null", empty artifacts, ensure keys
  // =====================================================================
  Map<String, dynamic> _normalizeParsedData(
    Map<String, dynamic> data,
    Map<String, String> schema,
  ) {
    final Map<String, dynamic> cleaned = <String, dynamic>{};

    bool isNullString(dynamic v) =>
        v is String && v.trim().toLowerCase() == 'null';

    dynamic clean(dynamic v) {
      if (isNullString(v)) {
        return null;
      }
      if (v is List) {
        // ignore: always_specify_types
        final List list = v.map(clean).where((e) => e != null).toList();
        return list;
      }
      if (v is Map) {
        // ignore: always_specify_types
        return v.map((k, value) => MapEntry(k, clean(value)));
      }
      return v;
    }

    for (final MapEntry<String, dynamic> entry in data.entries) {
      cleaned[entry.key] = clean(entry.value);
    }

    // Ensure all schema keys exist (add null if missing)
    for (final String key in schema.keys) {
      cleaned.putIfAbsent(key, () => null);
    }

    final List<String> nullFields = cleaned.entries
        .where((MapEntry<String, dynamic> e) => e.value == null)
        .map((MapEntry<String, dynamic> e) => e.key)
        .toList();
    if (nullFields.isNotEmpty) {
      _logger.debug('Fields resolved to null: $nullFields');
    }

    return cleaned;
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
