import 'dart:io';

import 'package:ai_webscraper/ai_webscraper.dart';
import 'package:dotenv/dotenv.dart';

/// Shared functionality for event scraping examples.
/// This module contains common code to avoid duplication between
/// the simple scraper and server implementations.
class EventScrapingHelper {
  /// Configure logging for event scraping examples
  static Future<void> configureLogging({
    LogLevel level = LogLevel.info,
    bool includeTimestamp = true,
    String? logFile,
  }) async {
    Logger.setLevel(level);
    Logger.configure(
      includeTimestamp: includeTimestamp,
      includeLevelName: true,
      outputToConsole: true,
    );

    if (logFile != null) {
      await Logger.setupFileLogging(logFile);
    }
  }

  /// Standard event data schema used across examples - returns array of events
  static Map<String, String> get eventSchema => {
        'events': 'array',
      };

  /// Alternative single event schema for pages with only one event
  static Map<String, String> get singleEventSchema => {
        'title': 'string',
        'description': 'text',
        'ticketLink': 'url',
        'date': 'string',
        'time': 'string',
        'venue': 'string',
        'price': 'string',
        'organizer': 'string',
      };

  /// Standard AI prompt for event extraction - supports multiple events
  static String get eventExtractionPrompt => '''
Extract ALL events from this webpage and return them as an array in JSON format.

Look for multiple events on the page - this could be:
- Event listing pages with multiple events
- Conference schedules with multiple sessions
- Event directories or search results
- Calendar pages with multiple dates
- Single event pages (return as array with one item)

Return JSON in this exact format:
{
  "events": [
    {
      "title": "Event name/title",
      "description": "Brief description or summary",
      "ticketLink": "Complete URL for tickets/registration (full URL with http/https)",
      "date": "Event date in readable format",
      "time": "Event time or schedule",
      "venue": "Location/venue/address",
      "price": "Pricing information or 'Free' or 'Not available'",
      "organizer": "Event organizer/host or 'Not available'"
    }
  ]
}

Important instructions:
- Find ALL events on the page, not just the first one
- Each event should be a separate object in the events array
- If only one event is found, still return it as an array with one item
- For any missing information, use "Not available" as the value
- For ticketLink, provide complete URLs starting with http/https
- Look thoroughly through the entire page including headers, sidebars, navigation, and footer
- Check for pagination or "load more" buttons that might indicate more events
- For conference pages, extract individual sessions as separate events if they have distinct information
  ''';

  /// Alternative prompt for single event pages
  static String get singleEventExtractionPrompt => '''
Extract comprehensive event information from this webpage and return in JSON format with these exact fields:

Required fields to extract:
- title: The main title or name of the event
- description: A brief description, summary, or details about what the event is about
- ticketLink: The complete URL where people can buy tickets or register (must be a full URL starting with http/https)
- date: The date when the event takes place (in any readable format)
- time: The time when the event starts or the schedule information
- venue: The location where the event takes place (venue name, address, or location details)
- price: Ticket price information, cost details, or pricing tiers
- organizer: Who is hosting or organizing the event

Important instructions:
- Return data in valid JSON format matching the exact field names above
- If any information is not found or available, use "Not available" as the value
- For ticketLink, provide the complete, clickable URL (not just partial links)
- For dates and times, extract in the most readable format available
- For price, include currency and any pricing details found
- Be thorough in searching the entire page content including headers, sidebars, and footer information
- Look for alternative terms like "register", "sign up", "buy now", "get tickets" for ticket links
  ''';

  /// Validate and get API key from .env file or environment
  static String getApiKey() {
    String? apiKey;

    // First, try to load from .env file
    try {
      final env = DotEnv();
      if (File('.env').existsSync()) {
        env.load(['.env']);
        apiKey = env['GEMINI_API_KEY'];
        if (apiKey != null && apiKey.isNotEmpty) {
          Logger.info('✅ Loaded GEMINI_API_KEY from .env file');
          return apiKey;
        }
      }
    } catch (e) {
      Logger.warning('Failed to load .env file: $e');
    }

    // Fallback to environment variable
    apiKey = const String.fromEnvironment('GEMINI_API_KEY');
    if (apiKey.isNotEmpty) {
      Logger.info('✅ Loaded GEMINI_API_KEY from environment variable');
      return apiKey;
    }

    // If neither worked, show error and exit
    Logger.error(
        '❌ GEMINI_API_KEY not found in .env file or environment variables');
    Logger.info('');
    Logger.info(
        '💡 Please set your Gemini API key using one of these methods:');
    Logger.info('');
    Logger.info('1. Create a .env file in the project root:');
    Logger.info('   GEMINI_API_KEY=your-api-key-here');
    Logger.info('');
    Logger.info('2. Set environment variable (Windows PowerShell):');
    Logger.info('   \$env:GEMINI_API_KEY="your-api-key-here"');
    Logger.info('');
    Logger.info('3. Use --define flag:');
    Logger.info('   dart run --define=GEMINI_API_KEY=your-key');
    Logger.info('');
    Logger.info(
        '4. Get your API key from: https://makersuite.google.com/app/apikey');
    exit(1);
  }

  /// Create and configure an AI WebScraper instance
  static AIWebScraper createScraper(String apiKey) {
    Logger.info('Initializing AI WebScraper with Gemini...');

    final scraper = AIWebScraper(
      aiModel: AIModel.gemini20FlashLite,
      apiKey: apiKey,
      timeout: const Duration(seconds: 45),
      useJavaScript:
          false, // Use JavaScript scraping for better content extraction
    );

    Logger.info('AI WebScraper initialized with Gemini 1.5 Pro');
    return scraper;
  }

  /// Extract event data from a URL with comprehensive logging
  static Future<ScrapingResult> extractEventData(
    AIWebScraper scraper,
    String url, {
    bool extractMultiple = false,
  }) async {
    Logger.info('Starting extraction for URL: $url');
    Logger.info(
        'Mode: ${extractMultiple ? 'Multiple events' : 'Single event'}');

    try {
      final stopwatch = Stopwatch()..start();

      final result = await scraper.extractFromUrl(
        url: url,
        schema: extractMultiple ? eventSchema : singleEventSchema,
        customInstructions: extractMultiple
            ? eventExtractionPrompt
            : singleEventExtractionPrompt,
      );

      stopwatch.stop();

      Logger.info('Extraction completed in ${stopwatch.elapsedMilliseconds}ms');
      Logger.info('Results Summary:');
      Logger.info('  - Fields extracted: ${result.fieldCount}');
      Logger.info(
          '  - Processing time: ${result.scrapingTime.inMilliseconds}ms');
      Logger.info('  - Has errors: ${result.hasError}');

      if (result.hasError) {
        Logger.warning('Error encountered during extraction:');
        Logger.warning('  • ${result.error}');
      }

      logExtractedData(result);
      logDataQualityAnalysis(result);

      return result;
    } catch (e, stackTrace) {
      Logger.error('Error extracting event data from $url', e, stackTrace);
      rethrow;
    }
  }

  /// Extract single event data (legacy method for backward compatibility)
  static Future<ScrapingResult> extractSingleEventData(
    AIWebScraper scraper,
    String url,
  ) async {
    return extractEventData(scraper, url, extractMultiple: false);
  }

  /// Log extracted event data in a formatted way - handles both single and multiple events
  static void logExtractedData(ScrapingResult result) {
    if (result.data != null) {
      // Check if we have an events array (multiple events) or single event data
      if (result.data!.containsKey('events') &&
          result.data!['events'] is List) {
        final events = result.data!['events'] as List;
        Logger.info('EXTRACTED EVENTS DATA (${events.length} events found):');
        Logger.info('=' * 50);

        for (int i = 0; i < events.length; i++) {
          Logger.info('📅 EVENT ${i + 1}/${events.length}:');
          Logger.info('-' * 30);

          if (events[i] is Map<String, dynamic>) {
            final event = events[i] as Map<String, dynamic>;
            event.forEach((key, value) {
              final capitalizedKey =
                  key.replaceAll(RegExp(r'([A-Z])'), ' \$1').toLowerCase();
              final formattedKey =
                  capitalizedKey[0].toUpperCase() + capitalizedKey.substring(1);
              Logger.info('  $formattedKey: $value');
            });
          } else {
            Logger.warning('  Invalid event data format at index $i');
          }

          if (i < events.length - 1)
            Logger.info(''); // Add spacing between events
        }
      } else {
        // Handle single event data (legacy format)
        Logger.info('EXTRACTED EVENT DATA:');
        Logger.info('-' * 40);

        result.data!.forEach((key, value) {
          final capitalizedKey =
              key.replaceAll(RegExp(r'([A-Z])'), ' \$1').toLowerCase();
          final formattedKey =
              capitalizedKey[0].toUpperCase() + capitalizedKey.substring(1);
          Logger.info('$formattedKey: $value');
        });
      }
    } else {
      Logger.warning('No data extracted');
    }
  }

  /// Log data quality analysis - handles both single and multiple events
  static void logDataQualityAnalysis(ScrapingResult result) {
    Logger.info('\n📈 DATA QUALITY ANALYSIS:');

    if (result.data != null) {
      // Handle multiple events
      if (result.data!.containsKey('events') &&
          result.data!['events'] is List) {
        final events = result.data!['events'] as List;
        Logger.info('  - Total events found: ${events.length}');

        if (events.isNotEmpty) {
          int eventsWithTitles = 0;
          int eventsWithDates = 0;
          int eventsWithTickets = 0;
          int eventsWithVenues = 0;
          int totalFieldsAvailable = 0;
          int totalPossibleFields = 0;

          for (final event in events) {
            if (event is Map<String, dynamic>) {
              totalPossibleFields += 8; // 8 fields per event

              // Count available fields
              final availableFields = event.values
                  .where((v) => v != null && v != 'Not available')
                  .length;
              totalFieldsAvailable += availableFields;

              // Count specific important fields
              if (event['title'] != null && event['title'] != 'Not available')
                eventsWithTitles++;
              if (event['date'] != null && event['date'] != 'Not available')
                eventsWithDates++;
              if (event['ticketLink'] != null &&
                  event['ticketLink'] != 'Not available') eventsWithTickets++;
              if (event['venue'] != null && event['venue'] != 'Not available')
                eventsWithVenues++;
            }
          }

          final overallCompleteness =
              (totalFieldsAvailable / totalPossibleFields * 100)
                  .toStringAsFixed(1);
          Logger.info(
              '  - Overall data completeness: $overallCompleteness% ($totalFieldsAvailable/$totalPossibleFields fields)');
          Logger.info(
              '  - Events with titles: $eventsWithTitles/${events.length} (${(eventsWithTitles / events.length * 100).toStringAsFixed(1)}%)');
          Logger.info(
              '  - Events with dates: $eventsWithDates/${events.length} (${(eventsWithDates / events.length * 100).toStringAsFixed(1)}%)');
          Logger.info(
              '  - Events with ticket links: $eventsWithTickets/${events.length} (${(eventsWithTickets / events.length * 100).toStringAsFixed(1)}%)');
          Logger.info(
              '  - Events with venues: $eventsWithVenues/${events.length} (${(eventsWithVenues / events.length * 100).toStringAsFixed(1)}%)');
        }
      } else {
        // Handle single event data (legacy format)
        final availableFields =
            result.data!.values.where((v) => v != 'Not available').length;
        final totalFields = result.data!.length;
        final completeness =
            (availableFields / totalFields * 100).toStringAsFixed(1);
        Logger.info(
            '  - Data completeness: $completeness% ($availableFields/$totalFields fields)');

        final hasTicketLink = result.data!['ticketLink'] != 'Not available';
        Logger.info(
            '  - Ticket link found: ${hasTicketLink ? '✅ Yes' : '❌ No'}');

        final hasDateTime = result.data!['date'] != 'Not available' &&
            result.data!['time'] != 'Not available';
        Logger.info('  - Date & time found: ${hasDateTime ? '✅ Yes' : '❌ No'}');
      }
    } else {
      Logger.info('  - No data available for analysis');
    }
  }

  /// Print API key setup instructions
  static void printApiKeyInstructions() {
    Logger.info('To set up your Gemini API key:');
    Logger.info('');
    Logger.info('1. Get your API key from Google AI Studio:');
    Logger.info('   https://makersuite.google.com/app/apikey');
    Logger.info('');
    Logger.info('2. Set the environment variable:');
    Logger.info('   Windows PowerShell:');
    Logger.info('     \$env:GEMINI_API_KEY="your-api-key-here"');
    Logger.info('');
    Logger.info('   Windows Command Prompt:');
    Logger.info('     set GEMINI_API_KEY=your-api-key-here');
    Logger.info('');
    Logger.info('   Linux/Mac:');
    Logger.info('     export GEMINI_API_KEY="your-api-key-here"');
  }

  /// Default event URLs for testing
  static List<String> get defaultEventUrls => [
        'https://www.flutterbytesconf.com/', // Single event
        // Add more test URLs as needed
      ];

  /// More comprehensive list for batch processing demos
  static List<String> get batchTestUrls => [
        // Tech conferences (likely single events)
        'https://www.flutterbytesconf.com/',
        'https://events.google.com/io/',

        // Event listing pages (likely multiple events)
        'https://www.eventbrite.com/d/online/tech-events/',
        'https://www.eventbrite.com/d/ca--toronto/business/',
        'https://www.meetup.com/find/?keywords=flutter',

        // Single events
        'https://www.eventbrite.com/e/flutterflow-meet-up-lagos-tickets-1542794873999',
        'https://www.meetup.com/flutter-toronto/',
        'https://www.meetup.com/gdg-toronto/',

        // University events (might have multiple events)
        'https://events.stanford.edu/',
        'https://events.mit.edu/',

        // Corporate events
        'https://build.microsoft.com/',
        'https://reinvent.awsevents.com/',
      ];

  /// URLs specifically selected for multiple events extraction
  static List<String> get multipleEventsTestUrls => [
        // Event directory/listing pages
        'https://www.eventbrite.com/d/online/tech-events/',
        'https://www.eventbrite.com/d/ca--toronto/business/',
        'https://www.meetup.com/find/?keywords=flutter',
        'https://lu.ma/discover',
        'https://events.google.com/search?q=tech',

        // Conference schedule pages
        'https://events.google.com/io/program/',
        'https://conference.flutter.dev/schedule',

        // University event calendars
        'https://events.stanford.edu/',
        'https://events.mit.edu/',

        // Local event aggregators
        'https://www.meetup.com/flutter-toronto/events/',
        'https://www.meetup.com/gdg-toronto/events/',
      ];

  /// Dynamic/JavaScript-heavy URLs for testing advanced features
  static List<String> get dynamicTestUrls => [
        'https://lu.ma/flutter-events',
        'https://www.eventbrite.com/d/online/tech-events/',
        'https://www.meetup.com/find/?keywords=flutter',
        'https://events.google.com/io/program/',
        'https://conference.flutter.dev/schedule',
      ];

  /// Extract event data from multiple URLs using batch processing
  static Future<List<ScrapingResult>> extractEventDataBatch(
    AIWebScraper scraper,
    List<String> urls, {
    int concurrency = 3,
    bool continueOnError = true,
    bool extractMultiple = true,
  }) async {
    Logger.info('Starting batch extraction for ${urls.length} URLs');
    Logger.info(
        'Concurrency: $concurrency, Continue on error: $continueOnError');
    Logger.info(
        'Mode: ${extractMultiple ? 'Multiple events per page' : 'Single event per page'}');

    try {
      final stopwatch = Stopwatch()..start();

      final results = await scraper.extractFromUrls(
        urls: urls,
        schema: extractMultiple ? eventSchema : singleEventSchema,
        concurrency: concurrency,
        continueOnError: continueOnError,
        customInstructions: extractMultiple
            ? eventExtractionPrompt
            : singleEventExtractionPrompt,
      );

      stopwatch.stop();

      Logger.info(
          'Batch extraction completed in ${stopwatch.elapsedMilliseconds}ms');

      final successful = results.where((r) => r.success).toList();
      Logger.info('Results: ${successful.length}/${results.length} successful');

      // Count total events extracted
      int totalEventsExtracted = 0;
      for (final result in successful) {
        if (result.data != null) {
          if (extractMultiple &&
              result.data!.containsKey('events') &&
              result.data!['events'] is List) {
            totalEventsExtracted += (result.data!['events'] as List).length;
          } else {
            totalEventsExtracted += 1; // Single event
          }
        }
      }

      Logger.info('Total events extracted: $totalEventsExtracted');

      return results;
    } catch (e, stackTrace) {
      Logger.error('Batch extraction failed', e, stackTrace);
      rethrow;
    }
  }

  /// Tips for better scraping results
  static void printScrapingTips() {
    Logger.info('Tips for better results:');
    Logger.info(
        '  • Use event pages with clear structure (Eventbrite, Facebook Events, etc.)');
    Logger.info('  • Ensure the URL is publicly accessible');
    Logger.info('  • Try different event types to test various layouts');
    Logger.info('');
    Logger.info('To customize:');
    Logger.info('  • Edit the URL list to add your target URLs');
    Logger.info('  • Modify the eventSchema to extract different fields');
    Logger.info('  • Adjust the AI prompt for specific extraction needs');
  }
}
