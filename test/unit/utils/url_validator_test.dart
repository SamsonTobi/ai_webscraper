import 'package:test/test.dart';
import 'package:ai_webscraper/ai_webscraper.dart';

void main() {
  group('URLValidator', () {
    late URLValidator validator;

    setUp(() {
      validator = URLValidator();
    });

    group('validate', () {
      test('should accept valid HTTP URLs', () {
        expect(
          () => validator.validate('http://example.com'),
          returnsNormally,
        );
      });

      test('should accept valid HTTPS URLs', () {
        expect(
          () => validator.validate('https://example.com'),
          returnsNormally,
        );
      });

      test('should accept URLs with paths', () {
        expect(
          () => validator.validate('https://example.com/path/to/page'),
          returnsNormally,
        );
      });

      test('should accept URLs with query parameters', () {
        expect(
          () => validator.validate('https://example.com?param=value'),
          returnsNormally,
        );
      });

      test('should accept URLs with fragments', () {
        expect(
          () => validator.validate('https://example.com#section'),
          returnsNormally,
        );
      });

      test('should accept URLs with ports', () {
        expect(
          () => validator.validate('https://example.com:8080/path'),
          returnsNormally,
        );
      });

      test('should accept complex URLs', () {
        expect(
          () => validator.validate(
            'https://user:pass@example.com:8080/path?param=value#section',
          ),
          returnsNormally,
        );
      });

      test('should throw URLValidationException for empty URL', () {
        expect(
          () => validator.validate(''),
          throwsA(isA<URLValidationException>()),
        );
      });

      test('should throw URLValidationException for whitespace-only URL', () {
        expect(
          () => validator.validate('   '),
          throwsA(isA<URLValidationException>()),
        );
      });

      test('should throw URLValidationException for unsupported scheme', () {
        expect(
          () => validator.validate('ftp://example.com'),
          throwsA(isA<URLValidationException>()),
        );

        expect(
          () => validator.validate('file:///path/to/file'),
          throwsA(isA<URLValidationException>()),
        );
      });

      test('should throw URLValidationException for malformed URLs', () {
        expect(
          () => validator.validate('not-a-url'),
          throwsA(isA<URLValidationException>()),
        );

        expect(
          () => validator.validate('http://'),
          throwsA(isA<URLValidationException>()),
        );

        expect(
          () => validator.validate('https://'),
          throwsA(isA<URLValidationException>()),
        );
      });

      test('should throw URLValidationException for relative URLs', () {
        expect(
          () => validator.validate('/relative/path'),
          throwsA(isA<URLValidationException>()),
        );

        expect(
          () => validator.validate('relative/path'),
          throwsA(isA<URLValidationException>()),
        );
      });

      test('should handle URLs with mixed case schemes', () {
        expect(
          () => validator.validate('HTTP://example.com'),
          returnsNormally,
        );

        expect(
          () => validator.validate('HTTPS://example.com'),
          returnsNormally,
        );
      });

      test('should trim whitespace from URLs', () {
        expect(
          () => validator.validate('  https://example.com  '),
          returnsNormally,
        );
      });

      test('should provide detailed error messages', () {
        try {
          validator.validate('ftp://example.com');
          fail('Expected URLValidationException');
        } on URLValidationException catch (e) {
          expect(e.message, contains('Unsupported URL scheme'));
          expect(e.message, contains('ftp'));
          expect(e.url, equals('ftp://example.com'));
        }
      });
    });

    group('validateAll', () {
      test('should validate all URLs when all are valid', () {
        final urls = [
          'https://example.com',
          'http://test.org',
          'https://another.site/path',
        ];

        expect(
          () => validator.validateAll(urls),
          returnsNormally,
        );
      });

      test('should throw on first invalid URL', () {
        final urls = [
          'https://example.com',
          'ftp://invalid.com',
          'https://another.site',
        ];

        expect(
          () => validator.validateAll(urls),
          throwsA(isA<URLValidationException>()),
        );
      });

      test('should handle empty list', () {
        expect(
          () => validator.validateAll([]),
          returnsNormally,
        );
      });
    });

    group('isValid', () {
      test('should return true for valid URLs', () {
        expect(validator.isValid('https://example.com'), isTrue);
        expect(validator.isValid('http://test.org/path'), isTrue);
      });

      test('should return false for invalid URLs', () {
        expect(validator.isValid(''), isFalse);
        expect(validator.isValid('not-a-url'), isFalse);
        expect(validator.isValid('ftp://example.com'), isFalse);
      });

      test('should not throw exceptions', () {
        expect(
          () => validator.isValid('invalid-url'),
          returnsNormally,
        );
      });
    });

    group('normalize', () {
      test('should add default scheme to URLs without scheme', () {
        expect(
          validator.normalize('example.com'),
          equals('https://example.com'),
        );

        expect(
          validator.normalize('test.org/path'),
          equals('https://test.org/path'),
        );
      });

      test('should use custom default scheme', () {
        expect(
          validator.normalize('example.com', 'http'),
          equals('http://example.com'),
        );
      });

      test('should not modify URLs that already have scheme', () {
        expect(
          validator.normalize('https://example.com'),
          equals('https://example.com'),
        );

        expect(
          validator.normalize('http://test.org'),
          equals('http://test.org'),
        );
      });

      test('should handle empty URLs', () {
        expect(validator.normalize(''), equals(''));
        expect(validator.normalize('   '), equals(''));
      });

      test('should trim whitespace', () {
        expect(
          validator.normalize('  example.com  '),
          equals('https://example.com'),
        );
      });
    });

    group('supportedSchemes', () {
      test('should return supported schemes', () {
        final schemes = validator.supportedSchemes;
        expect(schemes, contains('http'));
        expect(schemes, contains('https'));
        expect(schemes.length, equals(2));
      });

      test('should return immutable copy', () {
        final schemes1 = validator.supportedSchemes;
        final schemes2 = validator.supportedSchemes;

        expect(identical(schemes1, schemes2), isFalse);
      });
    });

    group('extractDomain', () {
      test('should extract domain from valid URLs', () {
        expect(
          validator.extractDomain('https://example.com'),
          equals('example.com'),
        );

        expect(
          validator.extractDomain('http://test.org/path'),
          equals('test.org'),
        );

        expect(
          validator.extractDomain(
              'https://subdomain.example.com:8080/path?param=value'),
          equals('subdomain.example.com'),
        );
      });

      test('should return null for invalid URLs', () {
        expect(validator.extractDomain('not-a-url'), isNull);
        expect(validator.extractDomain(''), isNull);
      });

      test('should handle URLs without scheme', () {
        expect(
          validator.extractDomain('example.com'),
          equals('example.com'),
        );
      });

      test('should trim whitespace', () {
        expect(
          validator.extractDomain('  https://example.com  '),
          equals('example.com'),
        );
      });
    });

    group('isLikelySPA', () {
      test('should detect SPA indicators in domain', () {
        expect(validator.isLikelySPA('https://app.example.com'), isTrue);
        expect(validator.isLikelySPA('https://admin.test.org'), isTrue);
        expect(validator.isLikelySPA('https://dashboard.site.com'), isTrue);
      });

      test('should detect SPA indicators in path', () {
        expect(validator.isLikelySPA('https://example.com/app/'), isTrue);
        expect(validator.isLikelySPA('https://test.org/admin/panel'), isTrue);
        expect(
            validator.isLikelySPA('https://site.com/dashboard/home'), isTrue);
        expect(validator.isLikelySPA('https://example.com/#/route'), isTrue);
      });

      test('should detect hash routing', () {
        expect(validator.isLikelySPA('https://example.com#route'), isTrue);
        expect(validator.isLikelySPA('https://test.org/#/app/home'), isTrue);
      });

      test('should return false for regular websites', () {
        expect(validator.isLikelySPA('https://example.com'), isFalse);
        expect(validator.isLikelySPA('https://blog.test.org'), isFalse);
        expect(validator.isLikelySPA('https://news.site.com/article'), isFalse);
      });

      test('should handle case insensitive matching', () {
        expect(validator.isLikelySPA('https://APP.example.com'), isTrue);
        expect(validator.isLikelySPA('https://example.com/APP/'), isTrue);
      });

      test('should handle invalid URLs gracefully', () {
        expect(validator.isLikelySPA('not-a-url'), isFalse);
        expect(validator.isLikelySPA(''), isFalse);
      });
    });

    group('error handling', () {
      test('URLValidationException should contain proper information', () {
        try {
          validator.validate('ftp://example.com');
          fail('Expected URLValidationException');
        } on URLValidationException catch (e) {
          expect(e.message, isNotEmpty);
          expect(e.url, equals('ftp://example.com'));
          expect(e.toString(), contains('ftp://example.com'));
          expect(e.toString(), contains(e.message));
        }
      });
    });

    group('edge cases', () {
      test('should handle very long URLs', () {
        final longPath = 'path' * 1000;
        final longUrl = 'https://example.com/$longPath';

        expect(
          () => validator.validate(longUrl),
          returnsNormally,
        );
      });

      test('should handle URLs with special characters', () {
        expect(
          () => validator.validate('https://example.com/path with spaces'),
          returnsNormally,
        );

        expect(
          () => validator
              .validate('https://example.com/path?query=special%20chars'),
          returnsNormally,
        );
      });

      test('should handle internationalized domain names', () {
        expect(
          () => validator.validate('https://例え.テスト'),
          returnsNormally,
        );
      });

      test('should handle IP addresses', () {
        expect(
          () => validator.validate('https://192.168.1.1'),
          returnsNormally,
        );

        expect(
          () => validator.validate('http://127.0.0.1:8080'),
          returnsNormally,
        );
      });
    });

    group('performance', () {
      test('should validate URLs efficiently', () {
        final urls = List.generate(1000, (i) => 'https://example$i.com');

        final stopwatch = Stopwatch()..start();

        for (final url in urls) {
          validator.validate(url);
        }

        stopwatch.stop();

        // Should complete within a reasonable time (adjust as needed)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('should check validity efficiently', () {
        final urls = List.generate(500, (i) => 'https://example$i.com')
          ..addAll(List.generate(500, (i) => 'invalid-url-$i'));

        final stopwatch = Stopwatch()..start();

        var validCount = 0;
        for (final url in urls) {
          if (validator.isValid(url)) {
            validCount++;
          }
        }

        stopwatch.stop();

        expect(validCount, equals(500));
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });
  });
}
