import 'package:ai_webscraper/src/core/ai_model.dart';
import 'package:ai_webscraper/src/core/ai_provider.dart';
import 'package:ai_webscraper/src/core/exceptions.dart';
import 'package:ai_webscraper/src/utils/response_cache.dart';

import 'ai_client_base.dart';
import 'gemini_client.dart';
import 'openai_client.dart';

/// Factory class for creating AI client instances based on provider type.
///
/// This factory implements the Factory pattern to create appropriate
/// AI client instances while hiding the implementation details from
/// the calling code.
class AIClientFactory {
  /// Creates an AI client instance for the specified AI model.
  ///
  /// [aiModel] - The specific AI model to use (contains both provider and model info)
  /// [apiKey] - The API key for authentication
  /// [timeout] - Optional timeout duration for API requests
  /// [options] - Optional provider-specific configuration
  /// [cache] - Optional response cache for storing AI responses
  ///
  /// Returns an appropriate [AIClientBase] implementation.
  /// Throws [UnsupportedProviderException] if the provider is not supported.
  static AIClientBase create(
    AIModel aiModel,
    String apiKey, {
    Duration timeout = const Duration(seconds: 30),
    Map<String, dynamic>? options,
    ResponseCache? cache,
  }) {
    if (apiKey.isEmpty) {
      throw ArgumentError('API key cannot be empty');
    }

    return switch (aiModel.provider) {
      AIProvider.openai => OpenAIClient(
          apiKey: apiKey,
          model: aiModel.modelName,
          timeout: timeout,
          options: options,
          cache: cache,
        ),
      AIProvider.gemini => GeminiClient(
          apiKey: apiKey,
          model: aiModel.modelName,
          timeout: timeout,
          options: options,
          cache: cache,
        ),
    };
  }

  /// Gets the list of supported AI providers.
  static List<AIProvider> get supportedProviders => [
        AIProvider.openai,
        AIProvider.gemini,
      ];

  /// Checks if a provider is supported by this factory.
  static bool isProviderSupported(AIProvider provider) {
    return supportedProviders.contains(provider);
  }

  /// Creates a client with validation of the API key format.
  ///
  /// This method performs basic validation of the API key format
  /// before creating the client instance.
  static AIClientBase createWithValidation(
    AIModel aiModel,
    String apiKey, {
    Duration timeout = const Duration(seconds: 30),
    Map<String, dynamic>? options,
    ResponseCache? cache,
  }) {
    final AIClientBase client = create(
      aiModel,
      apiKey,
      timeout: timeout,
      options: options,
      cache: cache,
    );

    if (!client.validateApiKey()) {
      throw InvalidApiKeyException(
        'API key format is invalid for provider ${aiModel.provider}',
      );
    }

    return client;
  }
}
