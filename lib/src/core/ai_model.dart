// ignore_for_file: public_member_api_docs

import 'ai_provider.dart';

/// Enumeration of all available AI models from supported providers
enum AIModel {
  // OpenAI GPT Models
  gpt4o('gpt-4o', AIProvider.openai),
  gpt4oMini('gpt-4o-mini', AIProvider.openai),
  gpt4Turbo('gpt-4-turbo', AIProvider.openai),
  gpt4TurboPreview('gpt-4-turbo-preview', AIProvider.openai),
  gpt4('gpt-4', AIProvider.openai),
  gpt35Turbo('gpt-3.5-turbo', AIProvider.openai),
  gpt35TurboInstruct('gpt-3.5-turbo-instruct', AIProvider.openai),

  // Google Gemini Models
  gemini25Pro('gemini-2.5-pro', AIProvider.gemini),
  gemini25Flash('gemini-2.5-flash', AIProvider.gemini),
  gemini20Flash('gemini-2.0-flash', AIProvider.gemini),
  gemini25FlashLite('gemini-2.5-flash-lite', AIProvider.gemini),
  gemini20FlashLite('gemini-2.0-flash-lite', AIProvider.gemini),
  geminiPro('gemini-pro', AIProvider.gemini),
  geminiProVision('gemini-pro-vision', AIProvider.gemini);

  const AIModel(this.modelName, this.provider);

  /// The actual model name as used by the API
  final String modelName;

  /// The AI provider that offers this model
  final AIProvider provider;

  /// Returns all OpenAI models
  static List<AIModel> get openaiModels => values
      .where((AIModel model) => model.provider == AIProvider.openai)
      .toList();

  /// Returns all Gemini models
  static List<AIModel> get geminiModels => values
      .where((AIModel model) => model.provider == AIProvider.gemini)
      .toList();

  /// Returns models for a specific provider
  static List<AIModel> modelsForProvider(AIProvider provider) {
    return values.where((AIModel model) => model.provider == provider).toList();
  }

  @override
  String toString() => modelName;
}
