# Changelog

All notable changes to the AI WebScraper package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned

- Add Claude AI provider support
- Create middleware system for request/response processing
- Add support for proxy configurations

## [0.2.1] - 2025-08-11

### Added
- **Solved Dart Analysis Issues**

## [0.2.0] - 2025-08-10

### Added

- **Response Caching System**: Comprehensive caching with in-memory and file-based storage
  - Configurable cache expiration and size limits
  - SHA-256 based cache keys for reliable deduplication
  - Automatic cache cleanup and persistence
  - Cache statistics and debugging support
- **Enhanced Logging**: Detailed logging throughout the scraping pipeline
  - Raw AI response logging for debugging
  - HTML content preview logging
  - Schema processing and field normalization logs
  - Scoped loggers for different components
- **Gemini ResponseSchema Support**: Proper implementation of Gemini's structured output
  - Native responseSchema integration instead of text-based prompts
  - Support for complex types: objects, typed arrays (array<string>, array<number>)
  - Required field marking with type! syntax
  - Automatic normalization of string "null" artifacts
- **Improved JavaScript Scraping**: Enhanced dynamic content handling
  - Better React/SPA content detection and waiting
  - Network idle waiting for complete page loads
  - Comprehensive page data extraction including structured data
  - Debug helpers for troubleshooting dynamic content issues

### Enhanced

- **AI Client Architecture**: More robust and feature-rich AI integration
  - Centralized response caching across all AI providers
  - Detailed response parsing with fallback extraction
  - Better error handling and provider-specific exceptions
  - Usage metadata tracking (where supported)
- **Schema Validation**: Extended type support and validation
  - Object type support for complex nested data
  - Typed array definitions for better structured output
  - Email, URL, and date/datetime specialized types
  - Flexible required field configuration
- **Web Scraper Core**: Improved reliability and debugging
  - Enhanced fallback logic between HTTP and JavaScript scraping
  - Better content formatting for AI processing
  - Comprehensive extraction data formatting
  - Improved error reporting and context

### Fixed

- Gemini API object schema validation errors (empty properties requirement)
- String "null" artifacts in AI responses converted to proper null values
- JavaScript scraping timeout and waiting issues for dynamic content
- Cache file corruption handling and error recovery
- Schema normalization ensuring all fields are present in responses

### Dependencies

- Added `crypto` package for secure cache key generation

## [0.1.2] - 2025-08-09

### Fixed

- Package dependency resolution issues
- Improved error handling in client initialization

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
