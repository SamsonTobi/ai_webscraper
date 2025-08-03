/// Enumeration of supported schema types for data extraction.
///
/// These types define the expected format of extracted data fields
/// and help the AI provider understand what kind of content to look for.
enum SchemaType {
  /// String/text content.
  ///
  /// Use for extracting text data like titles, descriptions, names, etc.
  /// Example: 'Product Name', 'Article Title', 'Author Name'
  string,

  /// Numeric values (integers or decimals).
  ///
  /// Use for extracting numerical data like prices, quantities, ratings, etc.
  /// Example: 29.99, 5, 4.5
  number,

  /// Boolean true/false values.
  ///
  /// Use for extracting binary states like availability, featured status, etc.
  /// Example: true, false
  boolean,

  /// Array/list of items.
  ///
  /// Use for extracting multiple items like tags, categories, image URLs, etc.
  /// Example: ['tag1', 'tag2', 'tag3']
  array,

  /// Nested object with key-value pairs.
  ///
  /// Use for extracting complex structured data with multiple fields.
  /// Example: {'width': 100, 'height': 200, 'unit': 'cm'}
  object,

  /// Date and time values.
  ///
  /// Use for extracting temporal data like publication dates, timestamps, etc.
  /// Example: '2023-12-01', '2023-12-01T10:30:00Z'
  date,

  /// Web URLs and links.
  ///
  /// Use for extracting web addresses, image URLs, reference links, etc.
  /// Example: 'https://example.com', 'https://example.com/image.jpg'
  url,

  /// Email addresses.
  ///
  /// Use for extracting contact email addresses.
  /// Example: 'contact@example.com'
  email,
}

/// Extension methods for SchemaType enum.
extension SchemaTypeExtension on SchemaType {
  /// Returns the display name of the schema type.
  String get displayName {
    switch (this) {
      case SchemaType.string:
        return 'String';
      case SchemaType.number:
        return 'Number';
      case SchemaType.boolean:
        return 'Boolean';
      case SchemaType.array:
        return 'Array';
      case SchemaType.object:
        return 'Object';
      case SchemaType.date:
        return 'Date';
      case SchemaType.url:
        return 'URL';
      case SchemaType.email:
        return 'Email';
    }
  }

  /// Returns a description of what this type represents.
  String get description {
    switch (this) {
      case SchemaType.string:
        return 'Text content like titles, names, descriptions';
      case SchemaType.number:
        return 'Numeric values like prices, quantities, ratings';
      case SchemaType.boolean:
        return 'True/false values like availability, status flags';
      case SchemaType.array:
        return 'Lists of items like tags, categories, URLs';
      case SchemaType.object:
        return 'Complex nested data with multiple fields';
      case SchemaType.date:
        return 'Date and time values like publication dates';
      case SchemaType.url:
        return 'Web URLs and links';
      case SchemaType.email:
        return 'Email addresses';
    }
  }

  /// Returns an example value for this type.
  String get exampleValue {
    switch (this) {
      case SchemaType.string:
        return '"Example Title"';
      case SchemaType.number:
        return '29.99';
      case SchemaType.boolean:
        return 'true';
      case SchemaType.array:
        return '["item1", "item2", "item3"]';
      case SchemaType.object:
        return '{"key": "value", "count": 5}';
      case SchemaType.date:
        return '"2023-12-01T10:30:00Z"';
      case SchemaType.url:
        return '"https://example.com"';
      case SchemaType.email:
        return '"contact@example.com"';
    }
  }
}
