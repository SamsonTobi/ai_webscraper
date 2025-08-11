import 'package:ai_webscraper/ai_webscraper.dart';
import 'event_scraping_helper.dart';

/// A simple standalone example that demonstrates event website scraping
/// using the AI WebScraper package with Gemini AI.
///
/// This example scrapes event websites and extracts structured data
/// like title, description, ticket link, date & time.
Future<void> main() async {
  // Configure logging
  await EventScrapingHelper.configureLogging();

  Logger.info('🎫 AI Event Scraper - Standalone Example');
  Logger.info('=' * 50);

  // Get API key and create scraper using helper
  final String apiKey = EventScrapingHelper.getApiKey();
  final AIWebScraper scraper = EventScrapingHelper.createScraper(apiKey);

  // Use default event URLs or customize as needed
  final List<String> eventUrls = EventScrapingHelper.defaultEventUrls;

  Logger.info(
      '📋 Extraction schema defined with ${EventScrapingHelper.eventSchema.length} fields');
  Logger.info('   Fields: ${EventScrapingHelper.eventSchema.keys.join(', ')}');

  // Process each URL
  for (int i = 0; i < eventUrls.length; i++) {
    final String url = eventUrls[i];
    Logger.info('\n${'=' * 80}');
    Logger.info('🎯 Processing Event ${i + 1}/${eventUrls.length}');
    Logger.info('📍 URL: $url');

    try {
      // Extract event data using the helper
      await EventScrapingHelper.extractEventData(scraper, url);
    } on Exception catch (e, stackTrace) {
      Logger.error('💥 Error processing URL: $url', e);
      Logger.debug('Stack trace', null, stackTrace);
      continue;
    }
  }

  Logger.info('\n${'=' * 80}');
  Logger.info('🎉 Event scraping completed!');

  // Print helpful tips
  EventScrapingHelper.printScrapingTips();
}

/// Helper function to demonstrate testing with a specific URL
Future<void> testSpecificEvent(String testUrl) async {
  // Configure logging
  await EventScrapingHelper.configureLogging(level: LogLevel.debug);

  Logger.info('🧪 Testing specific event URL: $testUrl');

  try {
    final String apiKey = EventScrapingHelper.getApiKey();
    final AIWebScraper scraper = EventScrapingHelper.createScraper(apiKey);

    await EventScrapingHelper.extractEventData(scraper, testUrl);
    Logger.info('Test completed successfully');
  } on Exception catch (e, stackTrace) {
    Logger.error('Test failed', e, stackTrace);
  }
}
