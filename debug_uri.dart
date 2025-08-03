void main() {
  final uri = Uri.parse('https://example.com');
  print('hasAbsolutePath: ${uri.hasAbsolutePath}');
  print('isAbsolute: ${uri.isAbsolute}');
  print('path: "${uri.path}"');
  print('host: "${uri.host}"');
  print('scheme: "${uri.scheme}"');
}
