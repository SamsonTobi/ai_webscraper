# Changelog

All notable changes to the AI WebScraper package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned

- Add Claude AI provider support
- Implement disk-based caching
- Add custom prompt templates
- Create middleware system for request/response processing
- Add support for proxy configurations

## [0.1.1] - 2025-08-04

### Fixed

- Fixed schema validation issue with complex array schema definitions
- Improved `ScrapingResult` JSON serialization for better API integration
- Fixed empty response handling in Gemini client

### Enhanced

- Better documentation for custom prompts feature
- Improved error messages for schema validation
- Enhanced examples with custom prompt usage

## [0.1.0] - 2025-08-01

### Added

- Initial release of AI WebScraper package
- Support for OpenAI GPT integration
- Support for Google Gemini integration
- Basic web scraping with HTTP requests
- JavaScript rendering with Puppeteer fallback
- Schema-based data extraction
- Batch processing with configurable concurrency
- Comprehensive error handling
- Type-safe result objects
- Automatic fallback from HTTP to JavaScript scraping
- Timeout configuration
- Basic logging and debugging support

### Core Features

- `AIWebScraper` main class with provider selection
- `ScrapingResult` for consistent result handling
- `AIProvider` enum for provider selection
- `SchemaType` enum for data type definitions
- Abstract AI client architecture for extensibility
- Factory pattern for AI client creation
- Batch processing utilities with semaphore-based concurrency control
- Schema validation and URL validation utilities

### AI Providers

- OpenAI GPT-3.5-turbo integration with Chat Completions API
- Google Gemini Pro integration with generative AI capabilities
- Structured JSON response handling for both providers
- Provider-specific error handling and retry logic

### Web Scraping

- HTTP-based scraping with configurable timeouts
- HTML content parsing and extraction
- JavaScript rendering support via Puppeteer
- Automatic fallback between scraping methods
- Content extraction utilities for clean data processing

### Testing

- Comprehensive unit test coverage
- Integration tests for end-to-end workflows
- Mock HTTP server for controlled testing
- AI API mocking for reliable testing
- Performance and concurrency testing

### Documentation

- Comprehensive README with usage examples
- API documentation with detailed method descriptions
- Example implementations for common use cases
- Configuration and setup guides
- Troubleshooting and best practices

---

## Release Notes

### Version 0.1.0 - Initial Release

This is the first stable release of AI WebScraper, providing core functionality for AI-powered web scraping with support for multiple AI providers and robust error handling.

**Key Highlights:**

- Production-ready AI integration with OpenAI and Google Gemini
- Efficient batch processing for multiple URLs
- Intelligent fallback mechanisms for reliable scraping
- Type-safe schema definitions for structured data extraction
- Comprehensive testing and documentation

**Getting Started:**

```dart
final scraper = AIWebScraper(
  aiProvider: AIProvider.openai,
  apiKey: 'your-api-key',
);

final result = await scraper.extractFromUrl(
  url: 'https://example.com',
  schema: {'title': 'string', 'price': 'number'},
);
```

**Performance:**

- Supports concurrent processing of multiple URLs
- Configurable timeouts and retry mechanisms
- Memory-efficient streaming for large content
- Optimized AI prompt construction for better results

**Reliability:**

- Extensive error handling for network and API failures
- Automatic retry logic with exponential backoff
- Graceful degradation from HTTP to JavaScript scraping
- Comprehensive logging for debugging and monitoring
