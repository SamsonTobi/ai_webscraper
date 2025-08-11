import 'package:ai_webscraper/ai_webscraper.dart';

/// Utility class for validating schema definitions.
///
/// This class ensures that schemas used for data extraction are valid
/// and contain supported field types.
class SchemaValidator {
  /// Set of supported schema field types.
  static const Set<String> _supportedTypes = <String>{
    'string',
    'number',
    'integer',
    'boolean',
    'array',
    'object',
    'date',
    'url',
    'email',
    'text',
  };

  /// Validates a schema definition.
  ///
  /// [schema] - The schema to validate as a map of field names to types
  ///
  /// Throws [SchemaValidationException] if the schema is invalid.
  void validate(Map<String, String> schema) {
    if (schema.isEmpty) {
      throw const SchemaValidationException('Schema cannot be empty');
    }

    for (final MapEntry<String, String> entry in schema.entries) {
      final String fieldName = entry.key;
      final String fieldType = entry.value;

      // Validate field name
      if (fieldName.trim().isEmpty) {
        throw const SchemaValidationException(
          'Schema field names cannot be empty',
        );
      }

      // Validate field type
      if (fieldType.trim().isEmpty) {
        throw SchemaValidationException(
          'Schema field type cannot be empty for field "$fieldName"',
        );
      }

      final String normalizedType = fieldType.toLowerCase().trim();
      if (!_supportedTypes.contains(normalizedType)) {
        throw SchemaValidationException(
          'Unsupported schema type "$fieldType" for field "$fieldName". '
          'Supported types: ${_supportedTypes.join(', ')}',
        );
      }
    }
  }

  /// Checks if a field type is supported.
  bool isTypeSupported(String type) {
    return _supportedTypes.contains(type.toLowerCase().trim());
  }

  /// Gets the list of supported field types.
  Set<String> get supportedTypes => Set.from(_supportedTypes);

  /// Normalizes a schema by converting field types to lowercase.
  Map<String, String> normalize(Map<String, String> schema) {
    return schema.map((String key, String value) => MapEntry(
          key.trim(),
          value.toLowerCase().trim(),
        ));
  }

  /// Validates and normalizes a schema in one operation.
  Map<String, String> validateAndNormalize(Map<String, String> schema) {
    final Map<String, String> normalized = normalize(schema);
    validate(normalized);
    return normalized;
  }
}
