/// Enumeration of supported AI providers for web scraping.
///
/// This enum defines the available AI providers that can be used
/// for content extraction from scraped web pages.
enum AIProvider {
  /// OpenAI GPT provider using the Chat Completions API.
  ///
  /// Features:
  /// - Fast response times
  /// - High accuracy for structured data extraction
  /// - JSON mode support for reliable parsing
  /// - Pay-per-token pricing model
  openai,

  /// Google Gemini provider using the Generative AI API.
  ///
  /// Features:
  /// - Fast response times
  /// - Good accuracy for content extraction
  /// - Cost-effective pricing
  /// - Integrated with Google AI ecosystem
  gemini,
}

/// Extension methods for AIProvider enum.
extension AIProviderExtension on AIProvider {
  /// Returns the display name of the AI provider.
  String get displayName {
    switch (this) {
      case AIProvider.openai:
        return 'OpenAI GPT';
      case AIProvider.gemini:
        return 'Google Gemini';
    }
  }

  /// Returns the model name used by the provider.
  String get defaultModel {
    switch (this) {
      case AIProvider.openai:
        return 'gpt-3.5-turbo';
      case AIProvider.gemini:
        return 'gemini-pro';
    }
  }

  /// Returns whether the provider supports JSON mode.
  bool get supportsJsonMode {
    switch (this) {
      case AIProvider.openai:
        return true;
      case AIProvider.gemini:
        return false;
    }
  }
}
