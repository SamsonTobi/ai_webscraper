/// Utility class for building AI prompts for content extraction.
///
/// This class provides methods to construct well-formatted prompts
/// that guide AI models to extract structured data from HTML content.
class PromptBuilder {
  /// Default system prompt for extraction tasks.
  static const String _defaultSystemPrompt = '''
You are a professional web scraping assistant. Your task is to extract structured data from HTML content and return it as valid JSON.

Guidelines:
1. Extract only the requested data fields
2. Return valid JSON that matches the provided schema
3. If a field is not found, use null for the value
4. For arrays, return empty arrays if no items are found
5. Preserve data types as specified in the schema
6. Do not include any explanatory text, only return the JSON
''';

  /// Builds an extraction prompt for the given HTML content and schema.
  ///
  /// [htmlContent] - The HTML content to extract data from
  /// [schema] - Map defining the fields to extract and their types
  /// [instructions] - Optional custom instructions
  /// [maxLength] - Maximum length of HTML content to include
  ///
  /// Returns a formatted prompt string ready for AI consumption.
  static String buildExtractionPrompt({
    required String htmlContent,
    required Map<String, String> schema,
    String? instructions,
    int maxLength = 50000,
  }) {
    final String truncatedContent = _truncateContent(htmlContent, maxLength);
    final String schemaDescription = _buildSchemaDescription(schema);
    final String customInstructions = instructions != null
        ? '\nAdditional Instructions:\n$instructions\n'
        : '';

    return '''
$_defaultSystemPrompt
$customInstructions
Schema to extract:
$schemaDescription

HTML Content:
$truncatedContent

Return only valid JSON matching the schema above.
''';
  }

  /// Builds a chat completion format prompt for OpenAI-style APIs.
  ///
  /// Returns a list of message objects suitable for chat completion APIs.
  static List<Map<String, String>> buildChatPrompt({
    required String htmlContent,
    required Map<String, String> schema,
    String? systemPrompt,
    String? instructions,
    int maxLength = 50000,
  }) {
    final String system = systemPrompt ?? _defaultSystemPrompt;
    final String userPrompt = buildExtractionPrompt(
      htmlContent: htmlContent,
      schema: schema,
      instructions: instructions,
      maxLength: maxLength,
    );

    return <Map<String, String>>[
      <String, String>{'role': 'system', 'content': system},
      <String, String>{'role': 'user', 'content': userPrompt},
    ];
  }

  /// Builds a simple text prompt suitable for single-turn models.
  ///
  /// This format works well with models that don't support chat formats.
  static String buildTextPrompt({
    required String htmlContent,
    required Map<String, String> schema,
    String? instructions,
    int maxLength = 50000,
  }) {
    return buildExtractionPrompt(
      htmlContent: htmlContent,
      schema: schema,
      instructions: instructions,
      maxLength: maxLength,
    );
  }

  /// Validates that a schema contains valid field definitions.
  ///
  /// Throws [ArgumentError] if the schema is invalid.
  static void validateSchema(Map<String, String> schema) {
    if (schema.isEmpty) {
      throw ArgumentError('Schema cannot be empty');
    }

    final Set<String> validTypes = <String>{
      'string',
      'number',
      'integer',
      'boolean',
      'array',
      'object',
      'date',
      'url',
      'email',
      'text'
    };

    for (final MapEntry<String, String> entry in schema.entries) {
      if (entry.key.isEmpty) {
        throw ArgumentError('Schema field names cannot be empty');
      }

      if (!validTypes.contains(entry.value.toLowerCase())) {
        throw ArgumentError(
            'Invalid schema type "${entry.value}" for field "${entry.key}". '
            'Valid types: ${validTypes.join(', ')}');
      }
    }
  }

  /// Estimates the token count for the given content.
  ///
  /// This is a rough estimation based on character count.
  /// Real token counting would require the specific tokenizer.
  static int estimateTokenCount(String content) {
    // Rough estimation: ~4 characters per token on average
    return (content.length / 4).ceil();
  }

  /// Builds a human-readable description of the schema.
  static String _buildSchemaDescription(Map<String, String> schema) {
    final StringBuffer buffer = StringBuffer()
    ..writeln('{');

    final List<MapEntry<String, String>> entries = schema.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final MapEntry<String, String> entry = entries[i];
      final String comma = i < entries.length - 1 ? ',' : '';
      buffer.writeln('  "${entry.key}": "${entry.value}"$comma');
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  /// Truncates HTML content to fit within token limits.
  static String _truncateContent(String content, int maxLength) {
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

  /// Creates a validation prompt to check if extracted data is reasonable.
  static String buildValidationPrompt({
    required Map<String, dynamic> extractedData,
    required Map<String, String> originalSchema,
    required String originalUrl,
  }) {
    return '''
Please validate this extracted data and check if it makes sense:

Original URL: $originalUrl
Expected Schema: ${_buildSchemaDescription(originalSchema)}
Extracted Data: $extractedData

Does this data look reasonable and complete? If not, what might be missing or incorrect?
Respond with "VALID" if the data looks good, or explain what issues you see.
''';
  }
}
