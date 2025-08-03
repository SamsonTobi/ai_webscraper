import 'lib/src/utils/url_validator.dart';

void main() {
  final URLValidator validator = URLValidator();

  // Test URLs that should be valid
  final List<String> validUrls = <String>[
    'https://example.com',
    'https://example.com#section',
    'https://user:pass@example.com:8080/path?param=value#section',
    'http://example.com',
  ];

  // Test URLs that should be invalid
  final List<String> invalidUrls = <String>[
    'example.com',
    'ftp://example.com',
    '/relative/path',
    '',
  ];

  print(' Testing valid URLs:');
  for (final String url in validUrls) {
    try {
      validator.validate(url);
      print('✓ $url - VALID');
    } catch (e) {
      print('✗ $url - INVALID: $e');
    }
  }

  print('\n Testing invalid URLs:');
  for (final String url in invalidUrls) {
    try {
      validator.validate(url);
      print('✗ $url - Should have been INVALID but was VALID');
    } catch (e) {
      print('✓ $url - INVALID: $e');
    }
  }

  print('\n Testing domain extraction:');
  final List<String> testUrls = <String>[
    'https://example.com',
    'https://subdomain.example.com:8080/path?param=value',
    'example.com',
    '',
    'not-a-url',
  ];

  for (final String url in testUrls) {
    final String? domain = validator.extractDomain(url);
    print('$url -> $domain');
  }
}
