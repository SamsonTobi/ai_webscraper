import 'package:ai_webscraper/ai_webscraper.dart';

/// Utility class for validating URLs.
///
/// This class ensures that URLs are properly formatted and use
/// supported protocols for web scraping.
class URLValidator {
  /// Set of supported URL schemes.
  static const Set<String> _supportedSchemes = {'http', 'https'};

  /// Validates a URL string.
  ///
  /// [url] - The URL to validate
  ///
  /// Throws [URLValidationException] if the URL is invalid.
  void validate(String url) {
    if (url.trim().isEmpty) {
      throw const URLValidationException('URL cannot be empty', '');
    }

    final trimmedUrl = url.trim();
    Uri parsedUri;

    try {
      parsedUri = Uri.parse(trimmedUrl);
    } catch (e) {
      throw URLValidationException(
        'Invalid URL format: $e',
        trimmedUrl,
      );
    }

    // Check if scheme is supported
    if (!_supportedSchemes.contains(parsedUri.scheme.toLowerCase())) {
      throw URLValidationException(
        'Unsupported URL scheme "${parsedUri.scheme}". '
        'Supported schemes: ${_supportedSchemes.join(', ')}',
        trimmedUrl,
      );
    }

    // Check if host is present
    if (parsedUri.host.isEmpty) {
      throw URLValidationException(
        'URL must have a valid host',
        trimmedUrl,
      );
    }

    // Additional validation for malformed URLs
    // For web scraping, we consider a URL valid if it has a scheme and host,
    // even if it has a fragment (which makes isAbsolute return false in Dart)
    if (!parsedUri.hasScheme || parsedUri.host.isEmpty) {
      throw URLValidationException(
        'URL must be absolute (have scheme and host)',
        trimmedUrl,
      );
    }
  }

  /// Validates multiple URLs.
  ///
  /// [urls] - List of URLs to validate
  ///
  /// Throws [URLValidationException] for the first invalid URL found.
  void validateAll(List<String> urls) {
    for (final url in urls) {
      validate(url);
    }
  }

  /// Checks if a URL is valid without throwing exceptions.
  ///
  /// [url] - The URL to check
  ///
  /// Returns true if the URL is valid, false otherwise.
  bool isValid(String url) {
    try {
      validate(url);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Normalizes a URL by ensuring it has a proper scheme.
  ///
  /// [url] - The URL to normalize
  /// [defaultScheme] - The default scheme to use if none is present
  ///
  /// Returns the normalized URL.
  String normalize(String url, [String defaultScheme = 'https']) {
    final trimmed = url.trim();

    if (trimmed.isEmpty) {
      return trimmed;
    }

    // If URL doesn't have a scheme, add the default one
    if (!trimmed.contains('://')) {
      return '$defaultScheme://$trimmed';
    }

    return trimmed;
  }

  /// Gets the list of supported URL schemes.
  Set<String> get supportedSchemes => Set.from(_supportedSchemes);

  /// Extracts the domain from a URL.
  ///
  /// [url] - The URL to extract the domain from
  ///
  /// Returns the domain string, or null if the URL is invalid.
  String? extractDomain(String url) {
    try {
      final trimmed = url.trim();
      if (trimmed.isEmpty) {
        return null;
      }

      final uri = Uri.parse(trimmed);

      // If the URI has a host, return it
      if (uri.host.isNotEmpty) {
        return uri.host;
      }

      // If no host but looks like a domain without scheme, try to extract it
      if (!uri.hasScheme && !trimmed.contains('/') && trimmed.contains('.')) {
        // This might be a domain without scheme like 'example.com'
        final withScheme = Uri.parse('http://$trimmed');
        if (withScheme.host.isNotEmpty) {
          return withScheme.host;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Checks if a URL is likely to be a single-page application (SPA).
  ///
  /// This is a heuristic check based on common patterns.
  bool isLikelySPA(String url) {
    final domain = extractDomain(url)?.toLowerCase() ?? '';
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';

    // Common SPA indicators
    final spaIndicators = [
      'app.',
      'admin.',
      'dashboard.',
    ];

    final pathIndicators = [
      '/app/',
      '/admin/',
      '/dashboard/',
      '/#/',
    ];

    return spaIndicators.any(domain.contains) ||
        pathIndicators.any(path.contains) ||
        url.contains('#');
  }
}
