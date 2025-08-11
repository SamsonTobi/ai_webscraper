import 'dart:developer' as debug;

import 'package:html/dom.dart';

/// Utility class for extracting and processing content from HTML documents.
///
/// This class provides various methods for extracting different types of
/// content from parsed HTML documents, including text, links, images,
/// metadata, and structured data.
class ContentExtractor {
  /// Elements that should be completely ignored during text extraction.
  static const List<String> _ignoredElements = <String>[
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
  static const List<String> _blockElements = <String>[
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
    final StringBuffer textBuffer = StringBuffer();
    final Element? bodyElement = document.body ?? document.documentElement;
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
      final int lastSpace = text.lastIndexOf(' ');
      if (lastSpace > maxLength * 0.8) {
        text = '${text.substring(0, lastSpace)}...';
      } else {
        text = '$text...';
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
    final Map<String, String> metadata = <String, String>{};

    // Extract title
    final Element? titleElement = document.querySelector('title');
    if (titleElement != null) {
      metadata['title'] = titleElement.text.trim();
    }

    // Extract meta tags
    final List<Element> metaTags = document.querySelectorAll('meta');
    for (final Element meta in metaTags) {
      final String name = meta.attributes['name'] ?? meta.attributes['property'] ?? '';
      final String content = meta.attributes['content'] ?? '';

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
    final Element? canonicalLink = document.querySelector('link[rel="canonical"]');
    if (canonicalLink != null) {
      final String? href = canonicalLink.attributes['href'];
      if (href != null) {
        metadata['canonical'] = href;
      }
    }

    // Extract language
    final Element? htmlElement = document.querySelector('html');
    if (htmlElement != null) {
      final String? lang = htmlElement.attributes['lang'];
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
    final List<String> links = <String>[];
    final List<Element> linkElements = document.querySelectorAll('a[href]');

    for (final Element link in linkElements) {
      final String? href = link.attributes['href'];
      if (href != null && href.isNotEmpty) {
        final String? resolvedUrl = _resolveUrl(href, baseUrl);
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
    final List<Map<String, String>> images = <Map<String, String>>[];
    final List<Element> imageElements = document.querySelectorAll('img[src]');

    for (final Element img in imageElements) {
      final String? src = img.attributes['src'];
      final String alt = img.attributes['alt'] ?? '';
      final String title = img.attributes['title'] ?? '';

      if (src != null && src.isNotEmpty) {
        final String? resolvedUrl = _resolveUrl(src, baseUrl);
        if (resolvedUrl != null) {
          images.add(<String, String>{
            'src': resolvedUrl,
            'alt': alt,
            'title': title,
          });
        }
      }
    }

    // Also extract images from picture elements
    final List<Element> pictureElements = document.querySelectorAll('picture source[srcset]');
    for (final Element source in pictureElements) {
      final String? srcset = source.attributes['srcset'];
      if (srcset != null && srcset.isNotEmpty) {
        final List<String> urls = _parseSrcset(srcset, baseUrl);
        for (final String url in urls) {
          images.add(<String, String>{
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
    final List<List<List<String>>> tables = <List<List<String>>>[];
    final List<Element> tableElements = document.querySelectorAll('table');

    for (final Element table in tableElements) {
      final List<List<String>> tableData = <List<String>>[];
      final List<Element> rows = table.querySelectorAll('tr');

      for (final Element row in rows) {
        final List<String> rowData = <String>[];
        final List<Element> cells = row.querySelectorAll('td, th');

        for (final Element cell in cells) {
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
    final List<Map<String, dynamic>> forms = <Map<String, dynamic>>[];
    final List<Element> formElements = document.querySelectorAll('form');

    for (final Element form in formElements) {
      final Map<String, dynamic> formData = <String, dynamic>{
        'action': form.attributes['action'] ?? '',
        'method': form.attributes['method'] ?? 'get',
        'fields': <Map<String, String>>[],
      };

      final List<Element> inputElements = form.querySelectorAll('input, textarea, select');
      for (final Element input in inputElements) {
        final Map<String, String> fieldData = <String, String>{
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
    for (final Node node in element.nodes) {
      if (node is Text) {
        final String text = node.text;
        if (text.trim().isNotEmpty) {
          buffer.write(text);
          if (preserveFormatting) {
            buffer.write(' ');
          }
        }
      } else if (node is Element) {
        final String tagName = node.localName?.toLowerCase() ?? '';

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
    for (final String tagName in _ignoredElements) {
      final List<Element> elements = document.querySelectorAll(tagName);
      for (final Element element in elements) {
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
    final List<Element> ogTags = document.querySelectorAll('meta[property^="og:"]');
    for (final Element tag in ogTags) {
      final String? property = tag.attributes['property'];
      final String? content = tag.attributes['content'];
      if (property != null && content != null) {
        metadata[property] = content;
      }
    }
  }

  /// Extracts Twitter Card metadata.
  void _extractTwitterMetadata(
      Document document, Map<String, String> metadata) {
    final List<Element> twitterTags = document.querySelectorAll('meta[name^="twitter:"]');
    for (final Element tag in twitterTags) {
      final String? name = tag.attributes['name'];
      final String? content = tag.attributes['content'];
      if (name != null && content != null) {
        metadata[name] = content;
      }
    }
  }

  /// Extracts structured data (JSON-LD, microdata, etc.).
  void _extractStructuredData(Document document, Map<String, String> metadata) {
    // Extract JSON-LD
    final List<Element> jsonLdScripts =
        document.querySelectorAll('script[type="application/ld+json"]');
    for (int i = 0; i < jsonLdScripts.length; i++) {
      final Element script = jsonLdScripts[i];
      metadata['json-ld-${i + 1}'] = script.text;
    }

    // Extract microdata (basic implementation)
    final List<Element> microdataElements = document.querySelectorAll('[itemscope]');
    for (int i = 0; i < microdataElements.length; i++) {
      final Element element = microdataElements[i];
      final String itemType = element.attributes['itemtype'] ?? '';
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
      final Uri base = Uri.parse(baseUrl);
      final Uri resolved = base.resolve(url);
      return resolved.toString();
    } on Exception catch (e) {
      debug.log('Failed to resolve URL: $url , $e');
      return null; // Invalid URL
    }
  }

  /// Parses srcset attribute to extract image URLs.
  List<String> _parseSrcset(String srcset, String? baseUrl) {
    final List<String> urls = <String>[];
    final List<String> parts = srcset.split(',');

    for (final String part in parts) {
      final String trimmed = part.trim();
      final int spaceIndex = trimmed.indexOf(' ');
      final String url = spaceIndex > 0 ? trimmed.substring(0, spaceIndex) : trimmed;

      if (url.isNotEmpty) {
        final String? resolvedUrl = _resolveUrl(url, baseUrl);
        if (resolvedUrl != null && !urls.contains(resolvedUrl)) {
          urls.add(resolvedUrl);
        }
      }
    }

    return urls;
  }
}
