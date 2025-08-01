# AI WebScraper

[![pub package](https://img.shields.io/pub/v/ai_webscraper.svg)](https://pub.dev/packages/ai_webscraper)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A powerful AI-powered web scraper for Dart that combines traditional web scraping with AI-based content extraction. Extract structured data from websites using OpenAI GPT or Google Gemini.

## Features

- 🤖 **Multiple AI Providers**: Support for OpenAI GPT and Google Gemini
- 🌐 **Smart Web Scraping**: HTTP requests with HTML parsing and JavaScript rendering fallback
- 📋 **Schema-Based Extraction**: Define JSON structures for consistent data extraction
- ⚡ **Batch Processing**: Process multiple URLs concurrently with configurable limits
- 🛡️ **Type Safety**: Full Dart type safety with comprehensive error handling
- 🔄 **Automatic Fallback**: Falls back from HTTP to JavaScript scraping when needed

## Quick Start

### Installation

Add `ai_webscraper` to your `pubspec.yaml`:

```yaml
dependencies:
  ai_webscraper: ^0.1.0
```

Then run:

```bash
dart pub get
```

### Basic Usage

```dart
import 'package:ai_webscraper/ai_webscraper.dart';

void main() async {
  // Initialize the scraper with OpenAI
  final scraper = AIWebScraper(
    aiProvider: AIProvider.openai,
    apiKey: 'your-openai-api-key',
  );

  // Define what data you want to extract
  final schema = {
    'title': 'string',
    'description': 'string',
    'price': 'number',
  };

  // Extract data from a single URL
  final result = await scraper.extractFromUrl(
    url: 'https://example-store.com/product/123',
    schema: schema,
  );

  if (result.success) {
    print('Extracted data: ${result.data}');
    print('Scraping took: ${result.scrapingTime.inMilliseconds}ms');
  } else {
    print('Error: ${result.error}');
  }
}
```

## Advanced Usage

### Using Google Gemini

```dart
final scraper = AIWebScraper(
  aiProvider: AIProvider.gemini,
  apiKey: 'your-gemini-api-key',
);
```

### Batch Processing

```dart
final urls = [
  'https://store1.com/product/1',
  'https://store2.com/product/2',
  'https://store3.com/product/3',
];

final results = await scraper.extractFromUrls(
  urls: urls,
  schema: {
    'name': 'string',
    'price': 'number',
    'availability': 'boolean',
  },
  concurrency: 3, // Process 3 URLs simultaneously
);

for (final result in results) {
  if (result.success) {
    print('${result.url}: ${result.data}');
  } else {
    print('Failed ${result.url}: ${result.error}');
  }
}
```

### JavaScript-Heavy Websites

For websites that require JavaScript rendering:

```dart
final result = await scraper.extractFromUrl(
  url: 'https://spa-website.com',
  schema: schema,
  useJavaScript: true, // Forces JavaScript rendering
);
```

### Error Handling

```dart
try {
  final result = await scraper.extractFromUrl(
    url: 'https://example.com',
    schema: {'title': 'string'},
  );

  if (result.success) {
    // Handle successful extraction
    print('Data: ${result.data}');
  } else {
    // Handle extraction failure
    print('Extraction failed: ${result.error}');
  }
} catch (e) {
  // Handle unexpected errors
  print('Unexpected error: $e');
}
```

## Schema Types

Define your data extraction schema using these supported types:

- `string` - Text content
- `number` - Numeric values (int or double)
- `boolean` - True/false values
- `array` - Lists of items
- `object` - Nested objects
- `date` - Date/time values
- `url` - Web URLs
- `email` - Email addresses

### Complex Schema Example

```dart
final schema = {
  'title': 'string',
  'price': 'number',
  'inStock': 'boolean',
  'images': 'array',
  'specifications': 'object',
  'publishDate': 'date',
  'contactEmail': 'email',
  'productUrl': 'url',
};
```

## Examples

### E-commerce Product Scraping

```dart
final result = await scraper.extractFromUrl(
  url: 'https://example-store.com/product/123',
  schema: {
    'name': 'string',
    'price': 'number',
    'description': 'string',
    'inStock': 'boolean',
    'rating': 'number',
    'images': 'array',
  },
);

if (result.success) {
  final product = result.data!;
  print('Product: ${product['name']}');
  print('Price: \$${product['price']}');
  print('Available: ${product['inStock']}');
}
```

### News Article Extraction

```dart
final result = await scraper.extractFromUrl(
  url: 'https://news-site.com/article/123',
  schema: {
    'headline': 'string',
    'author': 'string',
    'publishDate': 'date',
    'content': 'string',
    'tags': 'array',
  },
  useJavaScript: true,
);
```

### Real Estate Listings

```dart
final results = await scraper.extractFromUrls(
  urls: propertyUrls,
  schema: {
    'address': 'string',
    'price': 'number',
    'bedrooms': 'number',
    'bathrooms': 'number',
    'squareFeet': 'number',
    'description': 'string',
    'images': 'array',
  },
  concurrency: 2,
);
```

## Configuration

### Timeout Settings

```dart
final scraper = AIWebScraper(
  aiProvider: AIProvider.openai,
  apiKey: 'your-api-key',
  timeout: Duration(seconds: 60), // Custom timeout
);
```

### AI Provider Comparison

| Feature     | OpenAI GPT    | Google Gemini   |
| ----------- | ------------- | --------------- |
| Speed       | Fast          | Fast            |
| Accuracy    | High          | High            |
| Cost        | Pay per token | Pay per request |
| Rate Limits | High          | Moderate        |

## Error Handling

The package provides comprehensive error handling:

- **Network Errors**: Timeout, connection issues
- **AI API Errors**: Invalid keys, rate limits, service unavailable
- **Parsing Errors**: Invalid HTML, malformed responses
- **Schema Errors**: Invalid schema definitions
- **JavaScript Errors**: Puppeteer failures, rendering issues

## Performance Tips

1. **Use appropriate concurrency**: Start with 2-3 concurrent requests
2. **Batch similar requests**: Group URLs from the same domain
3. **Choose the right AI provider**: OpenAI for speed, Gemini for cost-effectiveness
4. **Use HTTP scraping first**: Only use JavaScript rendering when necessary
5. **Implement caching**: Cache results for frequently accessed URLs

## Requirements

- Dart SDK: `>=3.0.0 <4.0.0`
- Platform: Server-side Dart applications
- APIs: OpenAI API key and/or Google AI API key

## Getting API Keys

### OpenAI API Key

1. Visit [OpenAI Platform](https://platform.openai.com/)
2. Create an account or sign in
3. Navigate to API Keys section
4. Create a new API key

### Google Gemini API Key

1. Visit [Google AI Studio](https://makersuite.google.com/)
2. Create a project or select existing one
3. Generate an API key
4. Enable the Generative AI API

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📧 **Email**: support@aiwebscraper.dev
- 🐛 **Issues**: [GitHub Issues](https://github.com/yourusername/ai_webscraper/issues)
- 📖 **Documentation**: [API Documentation](https://pub.dev/documentation/ai_webscraper/latest/)

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a detailed list of changes and versions.

---

Made with ❤️ for the Dart community
