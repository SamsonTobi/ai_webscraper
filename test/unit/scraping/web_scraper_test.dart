import 'dart:io';

import 'package:ai_webscraper/src/core/exceptions.dart';
import 'package:ai_webscraper/src/scraping/web_scraper.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockResponse extends Mock implements http.Response {}

void main() {
  setUpAll(() {
    // Register fallback value for Uri to fix mocktail issues
    registerFallbackValue(Uri.parse('https://example.com'));
  });
  group('WebScraper', () {
    late WebScraper webScraper;
    late MockHttpClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockHttpClient();
      webScraper = WebScraper(client: mockHttpClient);
    });

    tearDown(() {
      // Clean up resources
    });

    group('Constructor Tests', () {
      test('should create instance with default parameters', () {
        final scraper = WebScraper();

        expect(scraper.timeout, equals(Duration(seconds: 30)));
        expect(scraper.userAgent, contains('AI-WebScraper'));
        expect(scraper.headers, isEmpty);
        expect(scraper.followRedirects, isTrue);
        expect(scraper.maxRedirects, equals(5));
      });

      test('should create instance with custom parameters', () {
        final customHeaders = {'Custom-Header': 'value'};
        final scraper = WebScraper(
          timeout: Duration(seconds: 60),
          userAgent: 'Custom User Agent',
          headers: customHeaders,
          followRedirects: false,
          maxRedirects: 3,
        );

        expect(scraper.timeout, equals(Duration(seconds: 60)));
        expect(scraper.userAgent, equals('Custom User Agent'));
        expect(scraper.headers, equals(customHeaders));
        expect(scraper.followRedirects, isFalse);
        expect(scraper.maxRedirects, equals(3));
      });
    });

    group('URL Validation Tests', () {
      test('should throw URLValidationException for invalid URL', () async {
        expect(
          () => webScraper.scrapeUrl('not-a-url'),
          throwsA(isA<URLValidationException>()),
        );
      });

      test('should throw URLValidationException for non-HTTP URL', () async {
        expect(
          () => webScraper.scrapeUrl('ftp://example.com'),
          throwsA(isA<URLValidationException>()),
        );
      });

      test('should accept valid HTTP URL', () async {
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(200);
        when(() => mockResponse.body)
            .thenReturn('<html><body>Test</body></html>');
        when(() => mockResponse.headers).thenReturn({});

        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => mockResponse);

        await webScraper.scrapeUrl('https://example.com');

        verify(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .called(1);
      });

      test('should accept valid HTTPS URL', () async {
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(200);
        when(() => mockResponse.body)
            .thenReturn('<html><body>Test</body></html>');
        when(() => mockResponse.headers).thenReturn({});

        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => mockResponse);

        await webScraper.scrapeUrl('https://example.com');

        verify(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .called(1);
      });
    });

    group('HTTP Request Tests', () {
      test('should make GET request with correct headers', () async {
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(200);
        when(() => mockResponse.body)
            .thenReturn('<html><body>Test</body></html>');
        when(() => mockResponse.headers).thenReturn({});

        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => mockResponse);

        await webScraper.scrapeUrl('https://example.com');

        final captured = verify(() => mockHttpClient.get(
              captureAny(),
              headers: captureAny(named: 'headers'),
            )).captured;

        final uri = captured[0] as Uri;
        final headers = captured[1] as Map<String, String>;

        expect(uri.toString(), equals('https://example.com'));
        expect(headers['User-Agent'], contains('AI-WebScraper'));
        expect(headers['Accept'], contains('text/html'));
        expect(headers['Connection'], equals('keep-alive'));
      });

      test('should include custom headers in request', () async {
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(200);
        when(() => mockResponse.body)
            .thenReturn('<html><body>Test</body></html>');
        when(() => mockResponse.headers).thenReturn({});

        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => mockResponse);

        await webScraper.scrapeUrl(
          'https://example.com',
          customHeaders: {'Authorization': 'Bearer token'},
        );

        final captured = verify(() => mockHttpClient.get(
              any(),
              headers: captureAny(named: 'headers'),
            )).captured;

        final headers = captured[0] as Map<String, String>;
        expect(headers['Authorization'], equals('Bearer token'));
      });

      test('should return HTML content for successful request', () async {
        const expectedHtml = '<html><body><h1>Test Page</h1></body></html>';
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(200);
        when(() => mockResponse.body).thenReturn(expectedHtml);
        when(() => mockResponse.headers).thenReturn({});

        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => mockResponse);

        final result = await webScraper.scrapeUrl('https://example.com');

        expect(result, equals(expectedHtml));
      });
    });

    group('HTTP Status Code Handling Tests', () {
      test('should handle 200 OK response', () async {
        const expectedHtml = '<html><body>Success</body></html>';
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(200);
        when(() => mockResponse.body).thenReturn(expectedHtml);
        when(() => mockResponse.headers).thenReturn({});

        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => mockResponse);

        final result = await webScraper.scrapeUrl('https://example.com');
        expect(result, equals(expectedHtml));
      });

      test('should handle 201 Created response', () async {
        const expectedHtml = '<html><body>Created</body></html>';
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(201);
        when(() => mockResponse.body).thenReturn(expectedHtml);
        when(() => mockResponse.headers).thenReturn({});

        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => mockResponse);

        final result = await webScraper.scrapeUrl('https://example.com');
        expect(result, equals(expectedHtml));
      });

      test('should throw ScrapingException for 404 Not Found', () async {
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(404);
        when(() => mockResponse.body).thenReturn('Not Found');
        when(() => mockResponse.headers).thenReturn({});

        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => mockResponse);

        expect(
          () => webScraper.scrapeUrl('https://example.com'),
          throwsA(isA<ScrapingException>().having(
            (e) => e.statusCode,
            'statusCode',
            equals(404),
          )),
        );
      });

      test('should throw ScrapingException for 500 Internal Server Error',
          () async {
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(500);
        when(() => mockResponse.body).thenReturn('Internal Server Error');
        when(() => mockResponse.headers).thenReturn({});

        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => mockResponse);

        expect(
          () => webScraper.scrapeUrl('https://example.com'),
          throwsA(isA<ScrapingException>().having(
            (e) => e.statusCode,
            'statusCode',
            equals(500),
          )),
        );
      });

      test('should handle redirect when followRedirects is true', () async {
        final redirectResponse = MockResponse();
        when(() => redirectResponse.statusCode).thenReturn(302);
        when(() => redirectResponse.headers).thenReturn({
          'location': 'https://example.com/redirected',
        });

        final finalResponse = MockResponse();
        when(() => finalResponse.statusCode).thenReturn(200);
        when(() => finalResponse.body)
            .thenReturn('<html><body>Redirected</body></html>');
        when(() => finalResponse.headers).thenReturn({});

        when(() => mockHttpClient.get(
              Uri.parse('https://example.com'),
              headers: any(named: 'headers'),
            )).thenAnswer((_) async => redirectResponse);

        when(() => mockHttpClient.get(
              Uri.parse('https://example.com/redirected'),
              headers: any(named: 'headers'),
            )).thenAnswer((_) async => finalResponse);

        final scraper =
            WebScraper(client: mockHttpClient, followRedirects: true);
        final result = await scraper.scrapeUrl('https://example.com');

        expect(result, equals('<html><body>Redirected</body></html>'));
      });

      test('should throw ScrapingException when followRedirects is false',
          () async {
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(302);
        when(() => mockResponse.headers).thenReturn({
          'location': 'https://example.com/redirected',
        });

        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => mockResponse);

        final scraper =
            WebScraper(client: mockHttpClient, followRedirects: false);

        expect(
          () => scraper.scrapeUrl('https://example.com'),
          throwsA(isA<ScrapingException>().having(
            (e) => e.message,
            'message',
            contains('Redirect not followed'),
          )),
        );
      });
    });

    group('Error Handling Tests', () {
      test('should throw TimeoutException on timeout', () async {
        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenThrow(TimeoutException(
                'Timeout', Duration(seconds: 30), 'https://example.com'));

        expect(
          () => webScraper.scrapeUrl('https://example.com'),
          throwsA(isA<TimeoutException>()),
        );
      });

      test('should throw ScrapingException on SocketException', () async {
        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenThrow(SocketException('Connection failed'));

        expect(
          () => webScraper.scrapeUrl('https://example.com'),
          throwsA(isA<ScrapingException>().having(
            (e) => e.message,
            'message',
            contains('Network connection failed'),
          )),
        );
      });

      test('should throw ScrapingException on HttpException', () async {
        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenThrow(HttpException('HTTP error'));

        expect(
          () => webScraper.scrapeUrl('https://example.com'),
          throwsA(isA<ScrapingException>().having(
            (e) => e.message,
            'message',
            contains('HTTP protocol error'),
          )),
        );
      });

      test('should throw URLValidationException on FormatException', () async {
        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenThrow(FormatException('Invalid URL format'));

        expect(
          () => webScraper.scrapeUrl('https://example.com'),
          throwsA(isA<URLValidationException>()),
        );
      });

      test('should throw ScrapingException on unexpected error', () async {
        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenThrow(Exception('Unexpected error'));

        expect(
          () => webScraper.scrapeUrl('https://example.com'),
          throwsA(isA<ScrapingException>().having(
            (e) => e.message,
            'message',
            contains('Unexpected error during HTTP request'),
          )),
        );
      });
    });

    group('Content Encoding Tests', () {
      test('should decode UTF-8 content correctly', () async {
        const htmlContent = '<html><body>Hello World! ñáéíóú</body></html>';
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(200);
        when(() => mockResponse.body).thenReturn(htmlContent);
        when(() => mockResponse.headers).thenReturn({
          'content-type': 'text/html; charset=utf-8',
        });

        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => mockResponse);

        final result = await webScraper.scrapeUrl('https://example.com');
        expect(result, equals(htmlContent));
      });

      test('should handle content without charset declaration', () async {
        const htmlContent = '<html><body>Hello World!</body></html>';
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(200);
        when(() => mockResponse.body).thenReturn(htmlContent);
        when(() => mockResponse.headers).thenReturn({
          'content-type': 'text/html',
        });

        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => mockResponse);

        final result = await webScraper.scrapeUrl('https://example.com');
        expect(result, equals(htmlContent));
      });
    });

    group('Content Extraction Tests', () {
      test('should extract clean HTML content', () async {
        const rawHtml = '''
          <html>
            <head>
              <title>Test Page</title>
              <script>console.log('test');</script>
              <style>body { color: red; }</style>
            </head>
            <body>
              <h1>Main Content</h1>
              <p>This is a paragraph.</p>
              <script>alert('popup');</script>
            </body>
          </html>
        ''';

        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(200);
        when(() => mockResponse.body).thenReturn(rawHtml);
        when(() => mockResponse.headers).thenReturn({});

        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => mockResponse);

        final result = await webScraper.scrapeUrl('https://example.com');

        // Should return the raw HTML as received (ContentExtractor processes it separately)
        expect(result, equals(rawHtml));
      });

      test('should handle empty response body', () async {
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(200);
        when(() => mockResponse.body).thenReturn('');
        when(() => mockResponse.headers).thenReturn({});

        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => mockResponse);

        final result = await webScraper.scrapeUrl('https://example.com');
        expect(result, equals(''));
      });

      test('should handle malformed HTML', () async {
        const malformedHtml =
            '<html><body><p>Unclosed paragraph<div>Nested improperly</p></div></body>';
        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(200);
        when(() => mockResponse.body).thenReturn(malformedHtml);
        when(() => mockResponse.headers).thenReturn({});

        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => mockResponse);

        final result = await webScraper.scrapeUrl('https://example.com');
        expect(result, equals(malformedHtml));
      });
    });

    group('Integration Tests', () {
      test('should handle complete scraping workflow', () async {
        const url = 'https://example.com/test-page';
        const htmlContent = '''
          <html>
            <head><title>Test Product</title></head>
            <body>
              <h1>Product Name</h1>
              <p class="price">\$19.99</p>
              <div class="description">
                This is a test product description.
              </div>
            </body>
          </html>
        ''';

        final mockResponse = MockResponse();
        when(() => mockResponse.statusCode).thenReturn(200);
        when(() => mockResponse.body).thenReturn(htmlContent);
        when(() => mockResponse.headers).thenReturn({
          'content-type': 'text/html; charset=utf-8',
        });

        when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
            .thenAnswer((_) async => mockResponse);

        final result = await webScraper.scrapeUrl(url);

        expect(result, equals(htmlContent));
        expect(result, contains('Product Name'));
        expect(result, contains(r'$19.99'));
        expect(result, contains('test product description'));
      });

      test('should maintain proper URL handling through redirects', () async {
        final redirectResponse = MockResponse();
        when(() => redirectResponse.statusCode).thenReturn(301);
        when(() => redirectResponse.headers).thenReturn({
          'location': '/final-page',
        });

        final finalResponse = MockResponse();
        when(() => finalResponse.statusCode).thenReturn(200);
        when(() => finalResponse.body)
            .thenReturn('<html><body>Final Page</body></html>');
        when(() => finalResponse.headers).thenReturn({});

        when(() => mockHttpClient.get(
              Uri.parse('https://example.com/redirect'),
              headers: any(named: 'headers'),
            )).thenAnswer((_) async => redirectResponse);

        when(() => mockHttpClient.get(
              Uri.parse('https://example.com/final-page'),
              headers: any(named: 'headers'),
            )).thenAnswer((_) async => finalResponse);

        final scraper =
            WebScraper(client: mockHttpClient, followRedirects: true);
        final result = await scraper.scrapeUrl('https://example.com/redirect');

        expect(result, equals('<html><body>Final Page</body></html>'));
        verify(() => mockHttpClient.get(
              Uri.parse('https://example.com/redirect'),
              headers: any(named: 'headers'),
            )).called(1);
        verify(() => mockHttpClient.get(
              Uri.parse('https://example.com/final-page'),
              headers: any(named: 'headers'),
            )).called(1);
      });
    });
  });
}
