# AI WebScraper Dart Package

## Package Overview

A standalone Dart package that combines web scraping with AI-powered content extraction. Users provide their own AI API keys and define JSON schemas for the AI to populate from scraped website content.

**Package Name**: `ai_webscraper`  
**Target Platforms**: Server-side Dart applications, Flutter backends  
**License**: MIT

## Core Features

- **Multi-AI Provider Support**: OpenAI, Google Gemini, Anthropic Claude, with extensible architecture
- **Schema-Based Extraction**: Users define JSON structure for AI to populate
- **Robust Web Scraping**: Multiple scraping strategies with fallback mechanisms
- **Type Safety**: Full Dart type safety with generics and schema validation
- **Configurable**: Timeout, retry, rate limiting, and caching options
- **Self-Deployable**: Users deploy with their own API keys and infrastructure

## Basic Usage

```dart
final scrapper = AIWebScrapper(
  aiProvider: AIProvider.openai,
  apiKey: 'your-api-key',
);

final result = await scrapper.scrapeAndExtract(
  url: 'https://example.com',
  schema: {
    'title': 'string',
    'description': 'string', 
    'price': 'number',
    'images': 'array<string>'
  },
);
```

## AI Provider Support

### Supported Providers

```dart
enum AIProvider {
  openai,
  gemini,
  claude,
  custom
}
```

### Provider-Specific Features

#### OpenAI Integration
- **Models**: GPT-4, GPT-4 Turbo, GPT-3.5 Turbo
- **Features**: Function calling, JSON mode, vision capabilities
- **Configuration**: Temperature, max tokens, top-p settings

#### Google Gemini Integration  
- **Models**: Gemini Pro, Gemini Pro Vision
- **Features**: Multimodal processing, safety settings
- **Configuration**: Generation config, safety thresholds

#### Anthropic Claude Integration
- **Models**: Claude-3 Opus, Claude-3 Sonnet, Claude-3 Haiku
- **Features**: Large context windows, function calling
- **Configuration**: Max tokens, temperature, stop sequences

#### Custom Provider Support
- **Interface**: `CustomAIProvider` abstract class
- **Requirements**: Implement text completion and optional vision methods
- **Use Cases**: Local models, other API providers, custom endpoints

## Scraping Strategies

### Strategy Hierarchy

```dart
enum ScrapingStrategy {
  basic,      // Simple HTTP requests with HTML parsing
  javascript, // JavaScript-enabled scraping for SPAs
  stealth,    // Anti-bot evasion techniques
  multi       // Multiple strategies with fallback
}
```

### Implementation Approaches

#### Basic Strategy
- **Dependencies**: `http`, `html`, `csslib`
- **Capabilities**: Static HTML parsing, CSS selectors, XPath
- **Use Cases**: Simple websites, blogs, documentation sites
- **Limitations**: No JavaScript execution

#### JavaScript Strategy  
- **Dependencies**: `puppeteer` (when available), `webdriver`
- **Capabilities**: Full browser rendering, SPA support, user interactions
- **Use Cases**: React/Vue apps, dynamic content, form interactions
- **Limitations**: Resource intensive, slower execution

#### Stealth Strategy
- **Dependencies**: Custom HTTP clients, proxy support
- **Capabilities**: Header rotation, proxy chains, rate limiting
- **Use Cases**: Protected sites, rate-limited APIs
- **Limitations**: May still be detected by advanced systems

#### Multi Strategy
- **Behavior**: Attempts strategies in order until success
- **Fallback Chain**: JavaScript → Stealth → Basic
- **Configuration**: Strategy priorities, timeout per attempt

## Schema Definition System

### Supported Data Types

```dart
enum SchemaType {
  string,
  number,
  boolean,
  array,
  object,
  date,
  url,
  email
}
```

### Schema Structure

#### Simple Schema
```dart
final schema = {
  'title': 'string',
  'price': 'number',
  'available': 'boolean',
  'publishedDate': 'date'
};
```

#### Complex Schema
```dart
final schema = {
  'product': {
    'name': 'string',
    'description': 'string',
    'specs': 'array<object>',
    'images': 'array<url>',
    'reviews': {
      'rating': 'number',
      'count': 'number',
      'comments': 'array<string>'
    }
  }
};
```

#### Array Schemas
```dart
final schema = {
  'articles': 'array<object>',
  'tags': 'array<string>',
  'prices': 'array<number>'
};
```

### Schema Validation

- **Pre-Processing**: Validate schema structure before scraping
- **Post-Processing**: Validate extracted data against schema
- **Type Coercion**: Automatic conversion between compatible types
- **Required Fields**: Mark fields as optional or required
- **Default Values**: Provide fallback values for missing data

## Configuration Options

### Global Configuration

```dart
final config = AIWebScraperConfig(
  timeout: Duration(seconds: 30),
  maxRetries: 3,
  retryDelay: Duration(seconds: 2),
  enableCaching: true,
  cacheTimeout: Duration(hours: 1),
  rateLimitPerSecond: 2,
  userAgent: 'Custom User Agent',
  enableLogging: true,
  logLevel: LogLevel.info
);

final scrapper = AIWebScrapper.withConfig(
  aiProvider: AIProvider.openai,
  apiKey: 'key',
  config: config,
);
```

### Per-Request Configuration

```dart
final result = await scrapper.scrapeAndExtract(
  url: 'https://example.com',
  schema: schema,
  options: ScrapingOptions(
    strategy: ScrapingStrategy.javascript,
    timeout: Duration(seconds: 45),
    waitForSelector: '.dynamic-content',
    scrollToBottom: true,
    extractImages: true
  ),
);
```

## Response Structure

### Success Response

```dart
class ScrapingResult<T> {
  final bool success;
  final T? data;
  final ScrapingMetadata metadata;
  final List<String> warnings;
  
  // Getters and methods
  bool get hasData => data != null;
  bool get hasWarnings => warnings.isNotEmpty;
}

class ScrapingMetadata {
  final Duration scrapingDuration;
  final Duration processingDuration;
  final ScrapingStrategy strategyUsed;
  final AIProvider aiProvider;
  final String aiModel;
  final int tokensUsed;
  final double confidence;
  final Map<String, dynamic> additionalInfo;
}
```

### Error Handling

```dart
enum ScrapingError {
  networkTimeout,
  invalidUrl,
  scrapingFailed,
  aiProcessingFailed,
  schemaValidationFailed,
  rateLimitExceeded,
  invalidApiKey,
  quotaExceeded
}

class ScrapingException implements Exception {
  final ScrapingError error;
  final String message;
  final String? url;
  final dynamic originalError;
}
```

## Advanced Features

### Batch Processing

```dart
final urls = [
  'https://site1.com',
  'https://site2.com', 
  'https://site3.com'
];

final results = await scrapper.scrapeAndExtractBatch(
  urls: urls,
  schema: schema,
  concurrency: 3,
  continueOnError: true,
);
```

### Custom Extraction Prompts

```dart
final result = await scrapper.scrapeAndExtract(
  url: 'https://example.com',
  schema: schema,
  customPrompt: '''
    Focus on extracting product information. 
    Ignore navigation menus and footer content.
    Pay special attention to price variations and discounts.
  ''',
);
```

### Caching System

```dart
enum CacheStrategy {
  none,
  memory,
  disk,
  custom
}

final scrapper = AIWebScrapper(
  aiProvider: AIProvider.openai,
  apiKey: 'key',
  cacheStrategy: CacheStrategy.disk,
  cacheConfig: CacheConfig(
    maxCacheSize: 100, // MB
    cacheTimeout: Duration(hours: 24),
    cacheDirectory: './cache',
  ),
);
```

### Middleware System

```dart
abstract class ScrapingMiddleware {
  Future<ScrapingRequest> beforeScraping(ScrapingRequest request);
  Future<ScrapingResult> afterScraping(ScrapingResult result);
  Future<AIProcessingRequest> beforeAIProcessing(AIProcessingRequest request);
  Future<AIProcessingResult> afterAIProcessing(AIProcessingResult result);
}

// Usage
final scrapper = AIWebScrapper(
  aiProvider: AIProvider.openai,
  apiKey: 'key',
  middleware: [
    LoggingMiddleware(),
    MetricsMiddleware(),
    CustomHeadersMiddleware(),
  ],
);
```

## Package Architecture

### Core Components

1. **AIWebScrapper** - Main package interface
2. **ScrapingEngine** - Handles web content extraction
3. **AIProcessor** - Manages AI provider interactions
4. **SchemaValidator** - Validates and processes schemas
5. **ConfigManager** - Handles configuration and settings
6. **CacheManager** - Manages caching strategies
7. **ErrorHandler** - Centralized error handling

### Extension Points

- **Custom AI Providers** - Implement `AIProvider` interface
- **Custom Scrapers** - Implement `ScrapingStrategy` interface  
- **Custom Middleware** - Implement `ScrapingMiddleware` interface
- **Custom Cache Backends** - Implement `CacheProvider` interface

## Dependencies Strategy

### Core Dependencies
- **http** - Basic HTTP requests
- **html** - HTML parsing and manipulation
- **csslib** - CSS selector support

### Optional Dependencies
- **puppeteer** - JavaScript rendering (when available)
- **dio** - Advanced HTTP client features
- **crypto** - Caching and security features
- **path** - File system operations

### AI Provider Dependencies
- **openai_dart** - OpenAI API integration
- **google_generative_ai** - Gemini API integration
- **claude_dart** - Anthropic Claude integration (if available)

## Installation & Setup

### Package Installation

```yaml
dependencies:
  ai_webscraper: ^1.0.0
  
# Optional dependencies for enhanced features
  puppeteer: ^3.5.0  # For JavaScript scraping
  dio: ^5.3.2        # For advanced HTTP features
```

### Environment Setup

```dart
// Minimal setup
final scrapper = AIWebScrapper(
  aiProvider: AIProvider.openai,
  apiKey: Platform.environment['OPENAI_API_KEY']!,
);

// Advanced setup
final scrapper = AIWebScrapper.withConfig(
  aiProvider: AIProvider.gemini,
  apiKey: Platform.environment['GEMINI_API_KEY']!,
  config: AIWebScraperConfig(
    timeout: Duration(seconds: 60),
    enableCaching: true,
    scrapingStrategy: ScrapingStrategy.multi,
  ),
);
```

## Use Cases

### E-commerce Product Extraction
- Product details, prices, specifications
- Inventory status, reviews, ratings
- Image galleries, variant information

### News and Content Scraping
- Article headlines, content, metadata
- Author information, publication dates
- Category tags, related articles

### Real Estate Listings
- Property details, prices, locations
- Features, amenities, contact information
- Image galleries, virtual tour links

### Event Information
- Event details, schedules, speakers
- Venue information, ticket prices
- Social media links, contact details

### Job Listings
- Job titles, descriptions, requirements
- Company information, salary ranges
- Application processes, contact details

## Deployment Considerations

### Self-Hosted Deployment
- Users deploy their own instances
- No shared infrastructure or API limits
- Full control over data and processing

### Resource Requirements
- **Memory**: 256MB minimum, 1GB recommended
- **CPU**: Single core sufficient for basic usage
- **Storage**: Dependent on caching requirements
- **Network**: Outbound HTTPS access required

### Security Considerations
- API keys stored securely by users
- No data transmission to package maintainers
- HTTPS-only connections to AI providers
- Optional proxy support for enhanced privacy

This package empowers developers to build AI-enhanced web scraping solutions while maintaining full control over their data and API usage.