import 'dart:async';
import 'dart:io';
import 'package:puppeteer/puppeteer.dart';
import '../core/exceptions.dart';

/// JavaScript-enabled web scraper using Puppeteer.
///
/// This scraper can handle dynamic content that requires JavaScript
/// execution, such as Single Page Applications (SPAs) and websites
/// that load content after the initial page load.
class JavaScriptScraper {
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
    this.viewport = const {
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
        args: [
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
      final response =
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
      final htmlContent = await page.content;

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

      final response =
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
      final result =
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

      final screenshotBytes = await page.screenshot(
        fullPage: fullPage,
      );

      // Save the screenshot to the specified path
      final file = File(outputPath);
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

    final results = <String, String>{};
    final semaphore = Semaphore(concurrency);

    final futures = urls.map((url) async {
      await semaphore.acquire();
      try {
        final content = await scrapeUrl(
          url,
          waitForSelector: waitForSelector,
          waitForTimeout: waitForTimeout,
        );
        return MapEntry(url, content);
      } catch (e) {
        if (!continueOnError) {
          rethrow;
        }
        print('Warning: Failed to scrape $url with JavaScript: $e');
        return MapEntry(url, '');
      } finally {
        semaphore.release();
      }
    });

    final completedResults = await Future.wait(futures);
    for (final entry in completedResults) {
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
      page.onRequest.listen((request) async {
        if (request.resourceType == ResourceType.image) {
          await request.abort();
        } else {
          await request.continueRequest();
        }
      });
    }
  }

  /// Waits for various conditions before proceeding with content extraction.
  Future<void> _waitForConditions(
    Page page, {
    String? waitForSelector,
    String? waitForFunction,
    Duration? waitForTimeout,
  }) async {
    // Wait for specific selector
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

    // Wait for custom function
    if (waitForFunction != null) {
      try {
        await page.waitForFunction(waitForFunction, timeout: timeout);
      } catch (e) {
        throw JavaScriptScrapingException(
          'Timeout waiting for function: $waitForFunction',
          page.url ?? 'unknown',
          'Function wait timeout: $e',
        );
      }
    }

    // Additional timeout if specified
    if (waitForTimeout != null) {
      await Future<void>.delayed(waitForTimeout);
    }
  }

  /// Removes specified elements from the page before content extraction.
  Future<void> _removeElements(Page page, List<String> selectors) async {
    for (final selector in selectors) {
      try {
        await page.evaluate<void>('''
          (selector) => {
            const elements = document.querySelectorAll(selector);
            elements.forEach(el => el.remove());
          }
        ''', args: [selector]);
      } catch (e) {
        // Log warning but continue - element removal is non-critical
        print(
            'Warning: Failed to remove elements with selector "$selector": $e');
      }
    }
  }

  /// Validates URL format and protocol.
  bool _isValidUrl(String url) {
    try {
      if (url.trim().isEmpty) return false;

      final uri = Uri.parse(url);
      return uri.hasScheme &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.hasAuthority &&
          uri.host.isNotEmpty; // Ensure host is not empty
    } catch (e) {
      return false;
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
  final bool offline;
  final int downloadThroughput;
  final int uploadThroughput;
  final int latency;

  const NetworkConditions({
    this.offline = false,
    required this.downloadThroughput,
    required this.uploadThroughput,
    required this.latency,
  });

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
  final int maxCount;
  int _currentCount;
  final List<Completer<void>> _waitQueue = <Completer<void>>[];

  Semaphore(this.maxCount) : _currentCount = maxCount;

  Future<void> acquire() async {
    if (_currentCount > 0) {
      _currentCount--;
      return;
    }

    final completer = Completer<void>();
    _waitQueue.add(completer);
    return completer.future;
  }

  void release() {
    if (_waitQueue.isNotEmpty) {
      final completer = _waitQueue.removeAt(0);
      completer.complete();
    } else {
      _currentCount++;
    }
  }
}
