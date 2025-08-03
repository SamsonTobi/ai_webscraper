void main() {
  bool isValidUrl(String url) {
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

  print('not-a-url: ${isValidUrl('not-a-url')}');
  print('ftp://example.com: ${isValidUrl('ftp://example.com')}');
  print('empty: ${isValidUrl('')}');
  print('http://: ${isValidUrl('http://')}');
}
