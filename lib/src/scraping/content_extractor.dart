import 'package:html/dom.dart';

/// Utility class for extracting and processing content from HTML documents.
///
/// This class provides various methods for extracting different types of
/// content from parsed HTML documents, including text, links, images,
/// metadata, and structured data.
class ContentExtractor {
  /// Elements that should be completely ignored during text extraction.
  static const List<String> _ignoredElements = [
    'script',
    'style',
    'noscript',
    'iframe',
    'object',
    'embed',
    'applet',
    'meta',
    'link',
    'base',
    'title', // Handled separately in metadata
  ];

  /// Elements that should be treated as block-level (add line breaks).
  static const List<String> _blockElements = [
    'div',
    'p',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'article',
    'section',
    'aside',
    'header',
    'footer',
    'main',
    'nav',
    'blockquote',
    'pre',
    'ul',
    'ol',
    'li',
    'dl',
    'dt',
    'dd',
    'table',
    'tr',
    'td',
    'th',
    'thead',
    'tbody',
    'tfoot',
    'caption',
    'address',
    'details',
    'summary',
    'fieldset',
    'legend',
    'form',
  ];

  /// Extracts clean text content from an HTML document.
  ///
  /// Removes scripts, styles, and other non-content elements while
  /// preserving the structure and readability of the text.
  ///
  /// [document] is the parsed HTML document.
  /// [preserveFormatting] determines whether to preserve line breaks and spacing.
  /// [maxLength] limits the length of extracted text (null for no limit).
  String extractTextContent(
    Document document, {
    bool preserveFormatting = false,
    int? maxLength,
  }) {
    // Remove ignored elements
    _removeIgnoredElements(document);

    // Extract text with proper formatting
    final textBuffer = StringBuffer();
    final bodyElement = document.body ?? document.documentElement;
    if (bodyElement != null) {
      _extractTextFromElement(bodyElement, textBuffer, preserveFormatting);
    }

    String text = textBuffer.toString();

    // Clean up whitespace
    if (!preserveFormatting) {
      text = _cleanWhitespace(text);
    }

    // Apply length limit if specified
    if (maxLength != null && text.length > maxLength) {
      text = text.substring(0, maxLength);
      // Try to end at a word boundary
      final lastSpace = text.lastIndexOf(' ');
      if (lastSpace > maxLength * 0.8) {
        text = text.substring(0, lastSpace) + '...';
      } else {
        text = text + '...';
      }
    }

    return text.trim();
  }

  /// Extracts specific elements from the document using CSS selectors.
  ///
  /// [document] is the parsed HTML document.
  /// [selector] is the CSS selector to match elements.
  List<Element> extractElements(Document document, String selector) {
    try {
      return document.querySelectorAll(selector);
    } catch (e) {
      // If CSS selector fails, try simple tag selection
      if (selector.contains('.') ||
          selector.contains('#') ||
          selector.contains('[')) {
        rethrow; // Complex selector that we can't handle simply
      }
      return document.getElementsByTagName(selector);
    }
  }

  /// Extracts metadata from the HTML document.
  ///
  /// Returns common metadata fields like title, description, keywords, etc.
  ///
  /// [document] is the parsed HTML document.
  Map<String, String> extractMetadata(Document document) {
    final metadata = <String, String>{};

    // Extract title
    final titleElement = document.querySelector('title');
    if (titleElement != null) {
      metadata['title'] = titleElement.text.trim();
    }

    // Extract meta tags
    final metaTags = document.querySelectorAll('meta');
    for (final meta in metaTags) {
      final name = meta.attributes['name'] ?? meta.attributes['property'] ?? '';
      final content = meta.attributes['content'] ?? '';

      if (name.isNotEmpty && content.isNotEmpty) {
        metadata[name.toLowerCase()] = content;
      }
    }

    // Extract Open Graph metadata
    _extractOpenGraphMetadata(document, metadata);

    // Extract Twitter Card metadata
    _extractTwitterMetadata(document, metadata);

    // Extract structured data (JSON-LD)
    _extractStructuredData(document, metadata);

    // Extract canonical URL
    final canonicalLink = document.querySelector('link[rel="canonical"]');
    if (canonicalLink != null) {
      final href = canonicalLink.attributes['href'];
      if (href != null) {
        metadata['canonical'] = href;
      }
    }

    // Extract language
    final htmlElement = document.querySelector('html');
    if (htmlElement != null) {
      final lang = htmlElement.attributes['lang'];
      if (lang != null) {
        metadata['language'] = lang;
      }
    }

    return metadata;
  }

  /// Extracts all links from the document.
  ///
  /// [document] is the parsed HTML document.
  /// [baseUrl] is used to resolve relative URLs.
  List<String> extractLinks(Document document, {String? baseUrl}) {
    final links = <String>[];
    final linkElements = document.querySelectorAll('a[href]');

    for (final link in linkElements) {
      final href = link.attributes['href'];
      if (href != null && href.isNotEmpty) {
        final resolvedUrl = _resolveUrl(href, baseUrl);
        if (resolvedUrl != null && !links.contains(resolvedUrl)) {
          links.add(resolvedUrl);
        }
      }
    }

    return links;
  }

  /// Extracts images from the document.
  ///
  /// Returns a list of maps containing image URL and alt text.
  ///
  /// [document] is the parsed HTML document.
  /// [baseUrl] is used to resolve relative URLs.
  List<Map<String, String>> extractImages(Document document,
      {String? baseUrl}) {
    final images = <Map<String, String>>[];
    final imageElements = document.querySelectorAll('img[src]');

    for (final img in imageElements) {
      final src = img.attributes['src'];
      final alt = img.attributes['alt'] ?? '';
      final title = img.attributes['title'] ?? '';

      if (src != null && src.isNotEmpty) {
        final resolvedUrl = _resolveUrl(src, baseUrl);
        if (resolvedUrl != null) {
          images.add({
            'src': resolvedUrl,
            'alt': alt,
            'title': title,
          });
        }
      }
    }

    // Also extract images from picture elements
    final pictureElements = document.querySelectorAll('picture source[srcset]');
    for (final source in pictureElements) {
      final srcset = source.attributes['srcset'];
      if (srcset != null && srcset.isNotEmpty) {
        final urls = _parseSrcset(srcset, baseUrl);
        for (final url in urls) {
          images.add({
            'src': url,
            'alt': '',
            'title': '',
          });
        }
      }
    }

    return images;
  }

  /// Extracts table data from the document.
  ///
  /// Returns a list of tables, each containing rows and cells.
  ///
  /// [document] is the parsed HTML document.
  List<List<List<String>>> extractTables(Document document) {
    final tables = <List<List<String>>>[];
    final tableElements = document.querySelectorAll('table');

    for (final table in tableElements) {
      final tableData = <List<String>>[];
      final rows = table.querySelectorAll('tr');

      for (final row in rows) {
        final rowData = <String>[];
        final cells = row.querySelectorAll('td, th');

        for (final cell in cells) {
          rowData.add(cell.text.trim());
        }

        if (rowData.isNotEmpty) {
          tableData.add(rowData);
        }
      }

      if (tableData.isNotEmpty) {
        tables.add(tableData);
      }
    }

    return tables;
  }

  /// Extracts form data from the document.
  ///
  /// Returns information about forms and their input fields.
  ///
  /// [document] is the parsed HTML document.
  List<Map<String, dynamic>> extractForms(Document document) {
    final forms = <Map<String, dynamic>>[];
    final formElements = document.querySelectorAll('form');

    for (final form in formElements) {
      final formData = <String, dynamic>{
        'action': form.attributes['action'] ?? '',
        'method': form.attributes['method'] ?? 'get',
        'fields': <Map<String, String>>[],
      };

      final inputElements = form.querySelectorAll('input, textarea, select');
      for (final input in inputElements) {
        final fieldData = <String, String>{
          'name': input.attributes['name'] ?? '',
          'type': input.attributes['type'] ?? 'text',
          'value': input.attributes['value'] ?? '',
          'placeholder': input.attributes['placeholder'] ?? '',
        };

        (formData['fields'] as List<Map<String, String>>).add(fieldData);
      }

      forms.add(formData);
    }

    return forms;
  }

  /// Extracts text content from a specific element recursively.
  void _extractTextFromElement(
    Element element,
    StringBuffer buffer,
    bool preserveFormatting,
  ) {
    for (final node in element.nodes) {
      if (node is Text) {
        final text = node.text;
        if (text.trim().isNotEmpty) {
          buffer.write(text);
          if (preserveFormatting) {
            buffer.write(' ');
          }
        }
      } else if (node is Element) {
        final tagName = node.localName?.toLowerCase() ?? '';

        // Skip ignored elements
        if (_ignoredElements.contains(tagName)) {
          continue;
        }

        // Add line breaks for block elements
        if (!preserveFormatting && _blockElements.contains(tagName)) {
          buffer.write('\n');
        }

        // Recursively extract from child elements
        _extractTextFromElement(node, buffer, preserveFormatting);

        // Add line breaks after block elements
        if (!preserveFormatting && _blockElements.contains(tagName)) {
          buffer.write('\n');
        }
      }
    }
  }

  /// Removes ignored elements from the document.
  void _removeIgnoredElements(Document document) {
    for (final tagName in _ignoredElements) {
      final elements = document.querySelectorAll(tagName);
      for (final element in elements) {
        element.remove();
      }
    }
  }

  /// Cleans up whitespace in extracted text.
  String _cleanWhitespace(String text) {
    return text
        .replaceAll(RegExp(r'\s+'),
            ' ') // Replace multiple whitespace with single space
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n') // Preserve paragraph breaks
        .trim();
  }

  /// Extracts Open Graph metadata.
  void _extractOpenGraphMetadata(
      Document document, Map<String, String> metadata) {
    final ogTags = document.querySelectorAll('meta[property^="og:"]');
    for (final tag in ogTags) {
      final property = tag.attributes['property'];
      final content = tag.attributes['content'];
      if (property != null && content != null) {
        metadata[property] = content;
      }
    }
  }

  /// Extracts Twitter Card metadata.
  void _extractTwitterMetadata(
      Document document, Map<String, String> metadata) {
    final twitterTags = document.querySelectorAll('meta[name^="twitter:"]');
    for (final tag in twitterTags) {
      final name = tag.attributes['name'];
      final content = tag.attributes['content'];
      if (name != null && content != null) {
        metadata[name] = content;
      }
    }
  }

  /// Extracts structured data (JSON-LD, microdata, etc.).
  void _extractStructuredData(Document document, Map<String, String> metadata) {
    // Extract JSON-LD
    final jsonLdScripts =
        document.querySelectorAll('script[type="application/ld+json"]');
    for (int i = 0; i < jsonLdScripts.length; i++) {
      final script = jsonLdScripts[i];
      metadata['json-ld-${i + 1}'] = script.text;
    }

    // Extract microdata (basic implementation)
    final microdataElements = document.querySelectorAll('[itemscope]');
    for (int i = 0; i < microdataElements.length; i++) {
      final element = microdataElements[i];
      final itemType = element.attributes['itemtype'] ?? '';
      if (itemType.isNotEmpty) {
        metadata['microdata-type-${i + 1}'] = itemType;
      }
    }
  }

  /// Resolves a relative URL against a base URL.
  String? _resolveUrl(String url, String? baseUrl) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url; // Already absolute
    }

    if (url.startsWith('//')) {
      return 'https:$url'; // Protocol-relative URL
    }

    if (baseUrl == null) {
      return null; // Cannot resolve without base URL
    }

    try {
      final base = Uri.parse(baseUrl);
      final resolved = base.resolve(url);
      return resolved.toString();
    } catch (e) {
      return null; // Invalid URL
    }
  }

  /// Parses srcset attribute to extract image URLs.
  List<String> _parseSrcset(String srcset, String? baseUrl) {
    final urls = <String>[];
    final parts = srcset.split(',');

    for (final part in parts) {
      final trimmed = part.trim();
      final spaceIndex = trimmed.indexOf(' ');
      final url = spaceIndex > 0 ? trimmed.substring(0, spaceIndex) : trimmed;

      if (url.isNotEmpty) {
        final resolvedUrl = _resolveUrl(url, baseUrl);
        if (resolvedUrl != null && !urls.contains(resolvedUrl)) {
          urls.add(resolvedUrl);
        }
      }
    }

    return urls;
  }
}
