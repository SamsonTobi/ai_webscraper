/// A basic AI-powered web scraper for Dart
///
/// This library provides a simple yet powerful way to scrape web content
/// using AI providers like OpenAI GPT and Google Gemini for structured
/// data extraction.
///
/// Example usage:
/// ```dart
/// final scraper = AIWebScraper(
///   aiModel: AIModel.gpt4o,
///   apiKey: 'your-openai-api-key',
/// );
///
/// final result = await scraper.extractFromUrl(
///   url: 'https://example.com',
///   schema: {
///     'title': 'string',
///     'description': 'string',
///     'price': 'number',
///   },
/// );
///
/// if (result.success) {
///   print('Extracted data: ${result.data}');
/// } else {
///   print('Error: ${result.error}');
/// }
/// ```
library;

export 'src/core/ai_model.dart';
export 'src/core/ai_provider.dart';
export 'src/core/ai_webscraper.dart';
export 'src/core/exceptions.dart';
export 'src/core/schema_type.dart';
export 'src/core/scraping_result.dart';
export 'src/utils/batch_processor.dart';
export 'src/utils/logger.dart';
// Utility classes for advanced usage
export 'src/utils/schema_validator.dart';
export 'src/utils/url_validator.dart';
