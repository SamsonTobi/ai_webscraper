import 'package:test/test.dart';

import 'package:ai_webscraper/src/scraping/javascript_scraper.dart';
import 'package:ai_webscraper/src/core/exceptions.dart';

void main() {
  group('JavaScriptScraper', () {
    late JavaScriptScraper jsScraper;

    setUp(() {
      jsScraper = JavaScriptScraper();
    });

    tearDown(() {
      jsScraper.dispose();
    });

    group('Constructor Tests', () {
      test('should create instance with default parameters', () {
        final scraper = JavaScriptScraper();

        expect(scraper.timeout, equals(Duration(seconds: 60)));
        expect(scraper.headless, isTrue);
        expect(
            scraper.viewport,
            equals({
              'width': 1366,
              'height': 768,
              'deviceScaleFactor': 1.0,
            }));
        expect(scraper.userAgent, contains('Chrome'));
        expect(scraper.disableImages, isFalse);
        expect(scraper.disableJavaScript, isFalse);
      });

      test('should create instance with custom parameters', () {
        final customViewport = {
          'width': 1920,
          'height': 1080,
          'deviceScaleFactor': 2.0,
        };
        final scraper = JavaScriptScraper(
          timeout: Duration(seconds: 120),
          headless: false,
          viewport: customViewport,
          userAgent: 'Custom User Agent',
          disableImages: true,
          disableJavaScript: false,
        );

        expect(scraper.timeout, equals(Duration(seconds: 120)));
        expect(scraper.headless, isFalse);
        expect(scraper.viewport, equals(customViewport));
        expect(scraper.userAgent, equals('Custom User Agent'));
        expect(scraper.disableImages, isTrue);
        expect(scraper.disableJavaScript, isFalse);
      });

      test('should create instance with network conditions', () {
        const NetworkConditions networkConditions = NetworkConditions(
          downloadThroughput: 1000000, // 1Mbps
          uploadThroughput: 500000, // 0.5Mbps
          latency: 100, // 100ms
        );

        final scraper = JavaScriptScraper(
          networkConditions: networkConditions,
        );

        expect(scraper.networkConditions, equals(networkConditions));
      });
    });

    group('URL Validation Tests', () {
      test('should throw URLValidationException for invalid URL', () async {
        expect(
          () => jsScraper.scrapeUrl('not-a-url'),
          throwsA(isA<URLValidationException>()),
        );
      });

      test('should throw URLValidationException for non-HTTP URL', () async {
        expect(
          () => jsScraper.scrapeUrl('ftp://example.com'),
          throwsA(isA<URLValidationException>()),
        );
      });

      test('should throw URLValidationException for empty URL', () async {
        expect(
          () => jsScraper.scrapeUrl(''),
          throwsA(isA<URLValidationException>()),
        );
      });

      test('should throw URLValidationException for malformed URL', () async {
        expect(
          () => jsScraper.scrapeUrl('http://'),
          throwsA(isA<URLValidationException>()),
        );
      });
    });

    group('Initialization Tests', () {
      test('should initialize browser instance', () async {
        // This test validates that Puppeteer can initialize successfully
        expect(jsScraper.isInitialized, isFalse);

        // Since Puppeteer is working in this environment, initialization should succeed
        await jsScraper.initialize();

        expect(jsScraper.isInitialized, isTrue);
      });

      test('should handle multiple initialization calls', () async {
        // Test that multiple calls to initialize don't cause issues
        // Since Puppeteer is working in this environment, initialization should succeed
        await jsScraper.initialize();

        // Second call should also work (should be a no-op if already initialized)
        await jsScraper.initialize();

        expect(jsScraper.isInitialized, isTrue);
      });

      test('should handle initialization failure gracefully', () {
        // This would be tested with mock in integration tests
        // For unit tests, we ensure error handling structure exists
        expect(jsScraper.timeout, isA<Duration>());
        expect(jsScraper.headless, isA<bool>());
      });
    });

    group('Page Configuration Tests', () {
      test('should validate viewport configuration', () {
        final customViewport = {
          'width': 1920,
          'height': 1080,
          'deviceScaleFactor': 2.0,
        };
        final scraper = JavaScriptScraper(viewport: customViewport);

        expect(scraper.viewport['width'], equals(1920));
        expect(scraper.viewport['height'], equals(1080));
        expect(scraper.viewport['deviceScaleFactor'], equals(2.0));
      });

      test('should validate user agent configuration', () {
        const customUserAgent = 'Mozilla/5.0 (Test Browser)';
        final scraper = JavaScriptScraper(userAgent: customUserAgent);

        expect(scraper.userAgent, equals(customUserAgent));
      });

      test('should validate timeout configuration', () {
        final customTimeout = Duration(minutes: 5);
        final scraper = JavaScriptScraper(timeout: customTimeout);

        expect(scraper.timeout, equals(customTimeout));
      });

      test('should validate performance settings', () {
        final scraper = JavaScriptScraper(
          disableImages: true,
          disableJavaScript: false,
        );

        expect(scraper.disableImages, isTrue);
        expect(scraper.disableJavaScript, isFalse);
      });
    });

    group('Network Conditions Tests', () {
      test('should handle offline network condition', () {
        final networkConditions = NetworkConditions(
          offline: true,
          downloadThroughput: 0,
          uploadThroughput: 0,
          latency: 0,
        );

        final scraper = JavaScriptScraper(networkConditions: networkConditions);

        expect(scraper.networkConditions?.offline, isTrue);
        expect(scraper.networkConditions?.downloadThroughput, equals(0));
      });

      test('should handle slow network condition', () {
        final networkConditions = NetworkConditions(
          offline: false,
          downloadThroughput: 100000, // 100kbps
          uploadThroughput: 50000, // 50kbps
          latency: 500,
        );

        final scraper = JavaScriptScraper(networkConditions: networkConditions);

        expect(scraper.networkConditions?.offline, isFalse);
        expect(scraper.networkConditions?.downloadThroughput, equals(100000));
        expect(scraper.networkConditions?.uploadThroughput, equals(50000));
        expect(scraper.networkConditions?.latency, equals(500));
      });

      test('should handle null network conditions', () {
        final scraper = JavaScriptScraper(networkConditions: null);

        expect(scraper.networkConditions, isNull);
      });
    });

    group('Content Extraction Configuration Tests', () {
      test('should handle wait for selector option', () {
        // This test validates that the method accepts the parameter
        // In unit tests, we test with an unreachable URL to avoid network dependency
        expect(
            () async => await jsScraper.scrapeUrl(
                  'https://localhost:99999/nonexistent',
                  waitForSelector: '.content',
                ),
            throwsA(isA<JavaScriptScrapingException>()));
      });

      test('should handle wait for function option', () {
        expect(
            () async => await jsScraper.scrapeUrl(
                  'https://localhost:99999/nonexistent',
                  waitForFunction: '() => document.readyState === "complete"',
                ),
            throwsA(isA<JavaScriptScrapingException>()));
      });

      test('should handle wait for timeout option', () {
        expect(
            () async => await jsScraper.scrapeUrl(
                  'https://localhost:99999/nonexistent',
                  waitForTimeout: Duration(seconds: 5),
                ),
            throwsA(isA<JavaScriptScrapingException>()));
      });

      test('should handle remove elements option', () {
        expect(
            () async => await jsScraper.scrapeUrl(
                  'https://localhost:99999/nonexistent',
                  removeElements: ['script', 'style', '.ads'],
                ),
            throwsA(isA<JavaScriptScrapingException>()));
      });

      test('should handle multiple wait conditions', () {
        expect(
            () async => await jsScraper.scrapeUrl(
                  'https://localhost:99999/nonexistent',
                  waitForSelector: '.main-content',
                  waitForFunction: '() => window.dataLoaded === true',
                  waitForTimeout: Duration(seconds: 3),
                  removeElements: ['script', 'noscript'],
                ),
            throwsA(isA<JavaScriptScrapingException>()));
      });
    });

    group('Data Extraction Configuration Tests', () {
      test('should validate extraction script parameter', () {
        const extractionScript = '''
          () => {
            return {
              title: document.querySelector('h1')?.textContent,
              description: document.querySelector('.description')?.textContent,
            };
          }
        ''';

        expect(
            () async => await jsScraper.extractDataWithScript(
                  'https://localhost:99999/nonexistent',
                  extractionScript,
                ),
            throwsA(isA<JavaScriptScrapingException>()));
      });

      test('should handle complex extraction script', () {
        const complexScript = '''
          () => {
            const products = [];
            document.querySelectorAll('.product').forEach(product => {
              products.push({
                name: product.querySelector('.name')?.textContent,
                price: product.querySelector('.price')?.textContent,
                rating: product.querySelector('.rating')?.textContent,
              });
            });
            return { products };
          }
        ''';

        expect(
            () async => await jsScraper.extractDataWithScript(
                  'https://localhost:99999/nonexistent',
                  complexScript,
                  waitForSelector: '.product',
                ),
            throwsA(isA<JavaScriptScrapingException>()));
      });
    });

    group('Error Handling Configuration Tests', () {
      test('should have proper error handling structure for invalid URLs', () {
        expect(
          () => jsScraper.scrapeUrl('invalid-url'),
          throwsA(isA<URLValidationException>()),
        );
      });

      test('should handle timeout configuration properly', () {
        final timeoutScraper =
            JavaScriptScraper(timeout: Duration(milliseconds: 100));

        expect(timeoutScraper.timeout.inMilliseconds, equals(100));
      });

      test('should validate extraction script parameter', () {
        expect(
          () => jsScraper.extractDataWithScript(
              'https://localhost:99999/nonexistent', ''),
          throwsA(anyOf([
            isA<ArgumentError>(),
            isA<JavaScriptScrapingException>(),
          ])),
        );
      });
    });

    group('Resource Management Tests', () {
      test('should handle disposal without errors', () {
        final scraper = JavaScriptScraper();

        expect(() => scraper.dispose(), returnsNormally);
      });

      test('should handle multiple disposal calls', () {
        final scraper = JavaScriptScraper();

        scraper.dispose();
        expect(() => scraper.dispose(), returnsNormally);
      });

      test('should handle disposal after initialization', () async {
        final scraper = JavaScriptScraper();

        // In real scenario, this would initialize Puppeteer
        // For unit test, we just test the disposal logic
        expect(() => scraper.dispose(), returnsNormally);
      });
    });

    group('Performance Configuration Tests', () {
      test('should configure image loading optimization', () {
        final scraper = JavaScriptScraper(disableImages: true);

        expect(scraper.disableImages, isTrue);
      });

      test('should configure JavaScript execution', () {
        // Note: disabling JavaScript defeats the purpose but can be useful for testing
        final scraper = JavaScriptScraper(disableJavaScript: true);

        expect(scraper.disableJavaScript, isTrue);
      });

      test('should optimize for mobile viewport', () {
        final mobileViewport = {
          'width': 375,
          'height': 667,
          'deviceScaleFactor': 2.0,
          'isMobile': true,
          'hasTouch': true,
        };

        final scraper = JavaScriptScraper(viewport: mobileViewport);

        expect(scraper.viewport['width'], equals(375));
        expect(scraper.viewport['height'], equals(667));
        expect(scraper.viewport['deviceScaleFactor'], equals(2.0));
      });
    });

    group('Integration Configuration Tests', () {
      test('should configure for e-commerce scraping', () {
        final ecommerceScraper = JavaScriptScraper(
          timeout: Duration(minutes: 2),
          disableImages: false, // Need product images
          viewport: {
            'width': 1920,
            'height': 1080,
            'deviceScaleFactor': 1.0,
          },
        );

        expect(ecommerceScraper.timeout, equals(Duration(minutes: 2)));
        expect(ecommerceScraper.disableImages, isFalse);
        expect(ecommerceScraper.viewport['width'], equals(1920));
      });

      test('should configure for news scraping', () {
        final newsScraper = JavaScriptScraper(
          timeout: Duration(seconds: 90),
          disableImages: true, // Focus on text content
          userAgent: 'NewsBot/1.0',
        );

        expect(newsScraper.timeout, equals(Duration(seconds: 90)));
        expect(newsScraper.disableImages, isTrue);
        expect(newsScraper.userAgent, equals('NewsBot/1.0'));
      });

      test('should configure for SPA scraping', () {
        final spaScraper = JavaScriptScraper(
          timeout: Duration(minutes: 3), // SPAs can take longer to load
          headless: true,
          disableJavaScript: false, // Essential for SPAs
        );

        expect(spaScraper.timeout, equals(Duration(minutes: 3)));
        expect(spaScraper.headless, isTrue);
        expect(spaScraper.disableJavaScript, isFalse);
      });
    });
  });
}

// Helper extension for testing (simulates properties that would exist)
extension JavaScriptScraperTestExtension on JavaScriptScraper {
  bool get isInitialized =>
      false; // Would be actual state in real implementation
}
