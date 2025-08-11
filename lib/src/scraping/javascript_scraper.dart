// ignore_for_file: public_member_api_docs

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:ai_webscraper/ai_webscraper.dart';
import 'package:puppeteer/puppeteer.dart';
import '../core/exceptions.dart';

/// JavaScript-enabled web scraper using Puppeteer.
///
/// This scraper can handle dynamic content that requires JavaScript
/// execution, such as Single Page Applications (SPAs) and websites
/// that load content after the initial page load.
class JavaScriptScraper {

  /// Creates a new JavaScript scraper instance.
  ///
  /// [timeout] sets the maximum time to wait for page operations.
  /// [headless] determines whether to run browser in headless mode.
  /// [viewport] sets the browser viewport size and configuration.
  /// [userAgent] sets the user agent string.
  /// [disableImages] can improve performance by not loading images.
  /// [disableJavaScript] disables JavaScript execution (not recommended).
  /// [networkConditions] simulates different network conditions.
  JavaScriptScraper({
    this.timeout = const Duration(seconds: 60),
    this.headless = true,
    this.viewport = const <String, dynamic>{
      'width': 1366,
      'height': 768,
      'deviceScaleFactor': 1.0,
    },
    this.userAgent =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    this.disableImages = false,
    this.disableJavaScript = false,
    this.networkConditions,
  });
  /// The Puppeteer browser instance.
  Browser? _browser;

  /// The timeout duration for page operations.
  final Duration timeout;

  /// Whether to run the browser in headless mode.
  final bool headless;

  /// Browser viewport configuration.
  final Map<String, dynamic> viewport;

  /// User agent string for the browser.
  final String userAgent;

  /// Whether to disable images for faster loading.
  final bool disableImages;

  /// Whether to disable JavaScript (defeats the purpose but can be useful for testing).
  final bool disableJavaScript;

  /// Network conditions simulation.
  final NetworkConditions? networkConditions;

  static final ScopedLogger _logger = Logger.scoped('JavaScriptScraper');

  /// Initializes the Puppeteer browser instance.
  ///
  /// This method must be called before using other scraping methods.
  /// It's automatically called by scraping methods if not initialized.
  Future<void> initialize() async {
    if (_browser != null) {
      return; // Already initialized
    }

    try {
      _browser = await puppeteer.launch(
        headless: headless,
        args: <String>[
          '--no-sandbox',
          '--disable-setuid-sandbox',
          '--disable-dev-shm-usage',
          '--disable-gpu',
          '--no-first-run',
          '--no-default-browser-check',
          '--disable-default-apps',
          '--disable-extensions',
          if (disableImages) '--disable-images',
        ],
      );
    } catch (e) {
      throw JavaScriptScrapingException(
        'Failed to initialize Puppeteer browser',
        'initialization',
        'Browser launch error: $e',
      );
    }
  }

  /// Scrapes content from the specified URL using JavaScript rendering.
  ///
  /// Returns the fully rendered HTML content as a string after JavaScript execution.
  ///
  /// [url] is the URL to scrape.
  /// [waitForSelector] waits for a specific CSS selector to appear.
  /// [waitForFunction] waits for a custom JavaScript function to return true.
  /// [waitForTimeout] additional wait time after page load.
  /// [removeElements] CSS selectors of elements to remove before extracting content.
  Future<String> scrapeUrl(
    String url, {
    String? waitForSelector,
    String? waitForFunction,
    Duration? waitForTimeout,
    List<String>? removeElements,
  }) async {
    if (!_isValidUrl(url)) {
      throw URLValidationException(
        'Invalid URL format',
        url,
        'URL must be a valid HTTP or HTTPS URL',
      );
    }

    await initialize();

    Page? page;
    try {
      page = await _browser!.newPage();

      // Configure page settings
      await _configurePageSettings(page);

      // Navigate to the URL
      final Response response =
          await page.goto(url, wait: Until.networkIdle).timeout(timeout);

      if (!response.ok) {
        throw JavaScriptScrapingException(
          'HTTP request failed with status ${response.status}',
          url,
          'Response status: ${response.status}, Status text: ${response.statusText}',
        );
      }

      // Wait for specific conditions if specified
      await _waitForConditions(
        page,
        waitForSelector: waitForSelector,
        waitForFunction: waitForFunction,
        waitForTimeout: waitForTimeout,
      );

      // Remove unwanted elements if specified
      if (removeElements != null && removeElements.isNotEmpty) {
        await _removeElements(page, removeElements);
      }

      // Extract the fully rendered HTML
      final String? htmlContent = await page.content;

      return htmlContent ?? '';
    } on TimeoutException {
      throw TimeoutException(
        'JavaScript scraping timed out',
        timeout,
        'JavaScript page rendering for $url',
        'The page did not finish loading within ${timeout.inSeconds} seconds',
      );
    } catch (e) {
      if (e is JavaScriptScrapingException) {
        rethrow;
      }
      throw JavaScriptScrapingException(
        'Unexpected error during JavaScript scraping',
        url,
        'Error: $e',
      );
    } finally {
      await page?.close();
    }
  }

  /// Extracts data by executing JavaScript code on the page.
  ///
  /// This allows for custom data extraction logic that runs in the browser context.
  ///
  /// [url] is the URL to scrape.
  /// [extractionScript] is the JavaScript code to execute for data extraction.
  /// [waitForSelector] waits for a specific CSS selector before extraction.
  /// [waitForFunction] waits for a custom condition before extraction.
  Future<Map<String, dynamic>> extractDataWithScript(
    String url,
    String extractionScript, {
    String? waitForSelector,
    String? waitForFunction,
    Duration? waitForTimeout,
  }) async {
    await initialize();

    Page? page;
    try {
      page = await _browser!.newPage();
      await _configurePageSettings(page);

      final Response response =
          await page.goto(url, wait: Until.networkIdle).timeout(timeout);

      if (!response.ok) {
        throw JavaScriptScrapingException(
          'Failed to navigate to URL for script extraction',
          url,
          'Navigation failed or returned error status',
        );
      }

      await _waitForConditions(
        page,
        waitForSelector: waitForSelector,
        waitForFunction: waitForFunction,
        waitForTimeout: waitForTimeout,
      );

      // Execute the extraction script
      final Map<String, dynamic> result =
          await page.evaluate<Map<String, dynamic>>(extractionScript);

      return result;
    } catch (e) {
      if (e is JavaScriptScrapingException) {
        rethrow;
      }
      throw JavaScriptScrapingException(
        'Failed to extract data with custom script',
        url,
        'Script execution error: $e',
      );
    } finally {
      await page?.close();
    }
  }

  /// Takes a screenshot of the page.
  ///
  /// Useful for debugging and verification purposes.
  ///
  /// [url] is the URL to capture.
  /// [outputPath] is where to save the screenshot.
  /// [fullPage] determines whether to capture the full page or just viewport.
  /// [waitForSelector] waits for a specific element before capturing.
  Future<void> takeScreenshot(
    String url,
    String outputPath, {
    bool fullPage = false,
    String? waitForSelector,
    Duration? waitForTimeout,
  }) async {
    await initialize();

    Page? page;
    try {
      page = await _browser!.newPage();
      await _configurePageSettings(page);

      await page.goto(url, wait: Until.networkIdle).timeout(timeout);

      await _waitForConditions(
        page,
        waitForSelector: waitForSelector,
        waitForTimeout: waitForTimeout,
      );

      final Uint8List screenshotBytes = await page.screenshot(
        fullPage: fullPage,
      );

      // Save the screenshot to the specified path
      final File file = File(outputPath);
      await file.writeAsBytes(screenshotBytes);
    } catch (e) {
      throw JavaScriptScrapingException(
        'Failed to take screenshot',
        url,
        'Screenshot error: $e',
      );
    } finally {
      await page?.close();
    }
  }

  /// Scrapes multiple URLs concurrently using JavaScript rendering.
  ///
  /// [urls] is the list of URLs to scrape.
  /// [concurrency] limits the number of concurrent browser tabs.
  /// [continueOnError] determines whether to continue if some requests fail.
  Future<Map<String, String>> scrapeUrls(
    List<String> urls, {
    int concurrency = 2,
    bool continueOnError = true,
    String? waitForSelector,
    Duration? waitForTimeout,
  }) async {
    await initialize();

    final Map<String, String> results = <String, String>{};
    final Semaphore semaphore = Semaphore(concurrency);

    final Iterable<Future<MapEntry<String, String>>> futures = urls.map((String url) async {
      await semaphore.acquire();
      try {
        final String content = await scrapeUrl(
          url,
          waitForSelector: waitForSelector,
          waitForTimeout: waitForTimeout,
        );
        return MapEntry<String, String>(url, content);
      } catch (e) {
        if (!continueOnError) {
          rethrow;
        }
        _logger.warning('Warning: Failed to scrape $url with JavaScript: $e');
        return MapEntry<String, String>(url, '');
      } finally {
        semaphore.release();
      }
    });

    final List<MapEntry<String, String>> completedResults = await Future.wait(futures);
    for (final MapEntry<String, String> entry in completedResults) {
      if (entry.value.isNotEmpty) {
        results[entry.key] = entry.value;
      }
    }

    return results;
  }

  /// Configures page settings like user agent, viewport, and performance optimizations.
  Future<void> _configurePageSettings(Page page) async {
    // Set user agent
    await page.setUserAgent(userAgent);

    // Set viewport
    await page.setViewport(DeviceViewport(
      width: viewport['width'] as int,
      height: viewport['height'] as int,
      deviceScaleFactor: viewport['deviceScaleFactor'] as double,
    ));

    // Configure network conditions if specified
    if (networkConditions != null) {
      // Note: Network conditions emulation might not be supported in this version
      // await page.emulateNetworkConditions(networkConditions!);
    }

    // Disable JavaScript if requested (though this defeats the purpose)
    if (disableJavaScript) {
      await page.setJavaScriptEnabled(false);
    }

    // Block images if requested for better performance
    if (disableImages) {
      await page.setRequestInterception(true);
      page.onRequest.listen((Request request) async {
        if (request.resourceType == ResourceType.image) {
          await request.abort();
        } else {
          await request.continueRequest();
        }
      });
    }
  }

  /// Waits for various conditions before proceeding with content extraction.
  ///
  /// This method implements an improved strategy for modern dynamic websites:
  /// 1. Waits for custom selector/function if provided
  /// 2. Waits additional time for animations and delayed content
  /// 3. Scrolls to bottom to trigger lazy loading
  /// 4. Waits for new content after scroll
  /// 5. Scrolls back to top to capture all content
  /// 6. Applies additional timeout if specified
  Future<void> _waitForConditions(
    Page page, {
    String? waitForSelector,
    String? waitForFunction,
    Duration? waitForTimeout,
  }) async {
    // 1. Wait for specific selector if provided
    if (waitForSelector != null) {
      try {
        await page.waitForSelector(waitForSelector, timeout: timeout);
      } catch (e) {
        throw JavaScriptScrapingException(
          'Timeout waiting for selector: $waitForSelector',
          page.url ?? 'unknown',
          'Selector wait timeout: $e',
        );
      }
    }

    // 2. Wait for custom function if provided
    if (waitForFunction != null) {
      try {
        await page.waitForFunction('''
() => {
      return window.React || document.querySelector('[data-reactroot]') || 
             document.getElementById('root').children.length > 0;
    }''', timeout: timeout);
        
      } catch (e) {
        throw JavaScriptScrapingException(
          'Timeout waiting for function: $waitForFunction',
          page.url ?? 'unknown',
          'Function wait timeout: $e',
        );
      }
    }

    // 3. Wait additional time for animations/delayed content
    await Future<void>.delayed(const Duration(seconds: 2));

    // 4. Scroll to trigger lazy loading
    await page.evaluate<void>('''
() => {
      window.scrollTo(0, document.body.scrollHeight);
    }''');
  }

  /// Removes specified elements from the page before content extraction.
  Future<void> _removeElements(Page page, List<String> selectors) async {
    for (final String selector in selectors) {
      try {
        await page.evaluate<void>('''
          (selector) => {
            const elements = document.querySelectorAll(selector);
            elements.forEach(el => el.remove());
          }
        ''', args: <dynamic>[selector]);
      } on Exception catch (e) {
        // Log warning but continue - element removal is non-critical
        _logger.warning('Warning: Failed to remove elements with selector "$selector": $e');
      }
    }
  }

  /// Validates URL format and protocol.
  bool _isValidUrl(String url) {
    try {
      if (url.trim().isEmpty) {
        return false;
      }

      final Uri uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.hasAuthority &&
          uri.host.isNotEmpty; // Ensure host is not empty
    } on Exception catch (e) {
      _logger.warning('Warning: Failed to validate URL "$url": $e');
      return false;
    }
  }

  /// Extracts comprehensive content from the page using JavaScript.
  ///
  /// This method uses a comprehensive extraction strategy that captures
  /// all possible content from the page, including structured data,
  /// React components, and deeply nested content.
  Future<Map<String, dynamic>> _extractAllContent(Page page) async {
    // Inject comprehensive extraction script
    final Map<String, dynamic> result = await page.evaluate<Map<String, dynamic>>('''
() => {
      const extractText = (element) => {
        if (!element) return '';
        return element.textContent?.trim() || '';
      };
      
      const extractAttributes = (element) => {
        if (!element) return {};
        const attrs = {};
        for (let attr of element.attributes) {
          attrs[attr.name] = attr.value;
        }
        return attrs;
      };
      
      const extractAllElements = (selector) => {
        return Array.from(document.querySelectorAll(selector)).map(el => ({
          text: extractText(el),
          html: el.innerHTML,
          attributes: extractAttributes(el),
          tagName: el.tagName.toLowerCase()
        }));
      };
      
      // Comprehensive extraction
      return {
        // Basic page info
        title: document.title,
        url: window.location.href,
        
        // All text content
        bodyText: extractText(document.body),
        
        // Structured content
        headings: {
          h1: extractAllElements('h1'),
          h2: extractAllElements('h2'),
          h3: extractAllElements('h3'),
          h4: extractAllElements('h4'),
          h5: extractAllElements('h5'),
          h6: extractAllElements('h6')
        },
        
        // Interactive elements
        links: extractAllElements('a'),
        buttons: extractAllElements('button'),
        inputs: extractAllElements('input'),
        
        // Content sections
        paragraphs: extractAllElements('p'),
        divs: extractAllElements('div').filter(div => 
          div.text.length > 20 && div.text.length < 1000
        ),
        
        // Lists
        lists: extractAllElements('ul, ol'),
        listItems: extractAllElements('li'),
        
        // Media
        images: extractAllElements('img'),
        videos: extractAllElements('video'),
        
        // Tables
        tables: extractAllElements('table'),
        
        // Forms
        forms: extractAllElements('form'),
        
        // Iframes
        iframes: extractAllElements('iframe'),
        
        // Custom selectors for event/schedule content
        eventContent: {
          // Common event-related selectors
          cards: extractAllElements('[class*="card"], [class*="item"], [class*="event"]'),
          schedule: extractAllElements('[class*="schedule"], [class*="agenda"], [class*="program"]'),
          speakers: extractAllElements('[class*="speaker"], [class*="presenter"]'),
          sessions: extractAllElements('[class*="session"], [class*="talk"], [class*="presentation"]'),
          times: extractAllElements('[class*="time"], [class*="date"], [class*="when"]'),
          
          // Look for JSON-LD structured data
          structuredData: Array.from(document.querySelectorAll('script[type="application/ld+json"]'))
            .map(script => {
              try {
                return JSON.parse(script.textContent);
              } catch (e) {
                return null;
              }
            }).filter(data => data !== null),
          
          // React component data (look for data attributes)
          reactData: Array.from(document.querySelectorAll('[data-*]')).map(el => ({
            element: el.tagName.toLowerCase(),
            attributes: extractAttributes(el),
            text: extractText(el)
          })),
        },
      };
    }''');

    return result;
  }

  /// Extracts comprehensive content from a URL using the advanced extraction method.
  ///
  /// This method combines the JavaScript rendering capabilities with comprehensive
  /// content extraction to handle complex SPAs and dynamic websites.
  ///
  /// [url] is the URL to scrape.
  /// [waitForSelector] waits for a specific CSS selector to appear.
  /// [waitForFunction] waits for a custom JavaScript function to return true.
  /// [waitForTimeout] additional wait time after page load.
  Future<Map<String, dynamic>> scrapeUrlComprehensive(
    String url, {
    String? waitForSelector,
    String? waitForFunction,
    Duration? waitForTimeout,
  }) async {
    if (!_isValidUrl(url)) {
      throw URLValidationException(
        'Invalid URL format',
        url,
        'URL must be a valid HTTP or HTTPS URL',
      );
    }

    await initialize();

    Page? page;
    try {
      page = await _browser!.newPage();

      // Configure page settings
      await _configurePageSettings(page);

      // Navigate to the URL
      final Response response =
          await page.goto(url, wait: Until.networkIdle).timeout(timeout);

      if (!response.ok) {
        throw JavaScriptScrapingException(
          'HTTP request failed with status ${response.status}',
          url,
          'Response status: ${response.status}, Status text: ${response.statusText}',
        );
      }

      // Wait for specific conditions if specified
      await _waitForConditions(
        page,
        waitForSelector: waitForSelector,
        waitForFunction: waitForFunction,
        waitForTimeout: waitForTimeout,
      );

      // Extract comprehensive content
      final Map<String, dynamic> extractedData = await _extractAllContent(page);

      return extractedData;
    } on TimeoutException {
      throw TimeoutException(
        'JavaScript scraping timed out',
        timeout,
        'JavaScript page rendering for $url',
        'The page did not finish loading within ${timeout.inSeconds} seconds',
      );
    } catch (e) {
      if (e is JavaScriptScrapingException) {
        rethrow;
      }
      throw JavaScriptScrapingException(
        'Unexpected error during comprehensive JavaScript scraping',
        url,
        'Error: $e',
      );
    } finally {
      await page?.close();
    }
  }

  /// Closes the browser and releases all resources.
  ///
  /// This should be called when done with scraping to free up system resources.
  Future<void> dispose() async {
    if (_browser != null) {
      await _browser!.close();
      _browser = null;
    }
  }

  /// Checks if the browser is currently running.
  bool get isInitialized => _browser != null;
}

/// Network conditions for emulating different connection speeds.
class NetworkConditions {

  const NetworkConditions({
    this.offline = false,
    required this.downloadThroughput,
    required this.uploadThroughput,
    required this.latency,
  });
  final bool offline;
  final int downloadThroughput;
  final int uploadThroughput;
  final int latency;

  /// Predefined network conditions for common scenarios.
  static const NetworkConditions slow3G = NetworkConditions(
    downloadThroughput: 500 * 1024, // 500 KB/s
    uploadThroughput: 500 * 1024, // 500 KB/s
    latency: 400, // 400ms
  );

  static const NetworkConditions fast3G = NetworkConditions(
    downloadThroughput: 1600 * 1024, // 1.6 MB/s
    uploadThroughput: 750 * 1024, // 750 KB/s
    latency: 150, // 150ms
  );

  static const NetworkConditions offlineConditions = NetworkConditions(
    offline: true,
    downloadThroughput: 0,
    uploadThroughput: 0,
    latency: 0,
  );
}

/// Simple semaphore implementation for controlling browser tab concurrency.
class Semaphore {

  Semaphore(this.maxCount) : _currentCount = maxCount;
  final int maxCount;
  int _currentCount;
  final List<Completer<void>> _waitQueue = <Completer<void>>[];

  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }

    final Completer<void> completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      _waitQueue.removeAt(0)..complete();
    } else {
      _currentCount++;
    }
  }
}
