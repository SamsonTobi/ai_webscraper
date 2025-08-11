// ignore_for_file: avoid_slow_async_io, avoid_catches_without_on_clauses, always_specify_types

import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'dart:io';

import 'logger.dart';

/// Cache entry for AI responses.
class CacheEntry {

  /// Creates a new cache entry.
  CacheEntry({
    required this.data,
    required this.timestamp,
    required this.rawResponse,
    required this.inputHash,
  });

  /// Creates a cache entry from JSON.
  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      rawResponse: json['rawResponse'] as String,
      inputHash: json['inputHash'] as String,
    );
  }
  /// The cached response data.
  final Map<String, dynamic> data;

  /// When this entry was created.
  final DateTime timestamp;

  /// The original AI provider response (raw).
  final String rawResponse;

  /// Hash of the input parameters.
  final String inputHash;

  /// Converts this cache entry to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'rawResponse': rawResponse,
      'inputHash': inputHash,
    };
  }

  /// Checks if this cache entry is still valid.
  bool isValid(Duration maxAge) {
    return DateTime.now().difference(timestamp) < maxAge;
  }
}

/// Response cache for AI extraction results.
///
/// Provides in-memory and optional file-based caching for AI responses
/// to avoid redundant API calls and preserve results for debugging.
class ResponseCache {

  /// Creates a new response cache.
  ///
  /// [cacheFilePath] - Optional file path for persistent caching
  /// [maxAge] - Maximum age for cache entries (default: 1 hour)
  /// [maxEntries] - Maximum entries in memory (default: 1000)
  ResponseCache({
    String? cacheFilePath,
    Duration maxAge = const Duration(hours: 1),
    int maxEntries = 1000,
  })  : _cacheFilePath = cacheFilePath,
        _maxAge = maxAge,
        _maxEntries = maxEntries;
  /// In-memory cache storage.
  final Map<String, CacheEntry> _cache = <String, CacheEntry>{};

  /// Path to the cache file.
  final String? _cacheFilePath;

  /// Maximum cache age before entries are considered stale.
  final Duration _maxAge;

  /// Maximum number of entries to keep in memory.
  final int _maxEntries;

  /// Logger for cache operations.
  static final ScopedLogger _logger = Logger.scoped('ResponseCache');

  /// Initializes the cache by loading from file if specified.
  Future<void> initialize() async {
    if (_cacheFilePath != null) {
      await _loadFromFile();
    }
  }

  /// Generates a cache key from input parameters.
  String _generateKey({
    required String htmlContent,
    required Map<String, String> schema,
    required String provider,
    Map<String, dynamic>? options,
  }) {
    final Map<String, Object> input = <String, Object>{
      'htmlContent': htmlContent,
      'schema': schema,
      'provider': provider,
      'options': options ?? <String, dynamic>{},
    };

    final String inputString = jsonEncode(input);
    final Uint8List bytes = utf8.encode(inputString);
    final Digest hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Stores a response in the cache.
  Future<void> store({
    required String htmlContent,
    required Map<String, String> schema,
    required String provider,
    required String rawResponse,
    required Map<String, dynamic> parsedData,
    Map<String, dynamic>? options,
  }) async {
    final String key = _generateKey(
      htmlContent: htmlContent,
      schema: schema,
      provider: provider,
      options: options,
    );

    final CacheEntry entry = CacheEntry(
      data: parsedData,
      timestamp: DateTime.now(),
      rawResponse: rawResponse,
      inputHash: key,
    );

    _cache[key] = entry;
    _logger.debug('Stored cache entry for key: ${key.substring(0, 16)}...');

    // Cleanup old entries if we exceed max
    await _cleanup();

    // Save to file if configured
    if (_cacheFilePath != null) {
      await _saveToFile();
    }
  }

  /// Retrieves a response from the cache.
  CacheEntry? get({
    required String htmlContent,
    required Map<String, String> schema,
    required String provider,
    Map<String, dynamic>? options,
  }) {
    final String key = _generateKey(
      htmlContent: htmlContent,
      schema: schema,
      provider: provider,
      options: options,
    );

    final CacheEntry? entry = _cache[key];
    if (entry == null) {
      _logger.debug('Cache miss for key: ${key.substring(0, 16)}...');
      return null;
    }

    if (!entry.isValid(_maxAge)) {
      _logger.debug('Cache entry expired for key: ${key.substring(0, 16)}...');
      _cache.remove(key);
      return null;
    }

    _logger.debug('Cache hit for key: ${key.substring(0, 16)}...');
    return entry;
  }

  /// Clears all cache entries.
  Future<void> clear() async {
    _cache.clear();
    _logger.info('Cache cleared');

    if (_cacheFilePath != null) {
      final File file = File(_cacheFilePath!);
      if (await file.exists()) {
        await file.delete();
        _logger.debug('Cache file deleted');
      }
    }
  }

  /// Gets cache statistics.
  Map<String, dynamic> getStats() {
    final int validEntries = _cache.values.where((CacheEntry e) => e.isValid(_maxAge)).length;
    
    return <String, dynamic>{
      'totalEntries': _cache.length,
      'validEntries': validEntries,
      'expiredEntries': _cache.length - validEntries,
      'maxAge': _maxAge.toString(),
      'maxEntries': _maxEntries,
      'cacheFilePath': _cacheFilePath,
    };
  }

  /// Removes expired entries and enforces size limits.
  Future<void> _cleanup() async {
    // Remove expired entries
    final List<String> expiredKeys = <String>[];
    
    for (final MapEntry<String, CacheEntry> entry in _cache.entries) {
      if (!entry.value.isValid(_maxAge)) {
        expiredKeys.add(entry.key);
      }
    }
    
    for (final String key in expiredKeys) {
      _cache.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      _logger.debug('Removed ${expiredKeys.length} expired cache entries');
    }

    // Enforce size limit by removing oldest entries
    if (_cache.length > _maxEntries) {
      final List<MapEntry<String, CacheEntry>> sortedEntries = _cache.entries.toList()
        ..sort((MapEntry<String, CacheEntry> a, MapEntry<String, CacheEntry> b) => a.value.timestamp.compareTo(b.value.timestamp));
      
      final int toRemove = _cache.length - _maxEntries;
      for (int i = 0; i < toRemove; i++) {
        _cache.remove(sortedEntries[i].key);
      }
      
      _logger.debug('Removed $toRemove old cache entries to enforce size limit');
    }
  }

  /// Loads cache from file.
  Future<void> _loadFromFile() async {
    if (_cacheFilePath == null) {
      return;
    }

    try {
      final File file = File(_cacheFilePath!);
      if (!await file.exists()) {
        _logger.debug('Cache file does not exist, starting with empty cache');
        return;
      }

      final String content = await file.readAsString();
      final Map<String, dynamic> jsonData = jsonDecode(content) as Map<String, dynamic>;
      
      final Map<String, dynamic> entries = jsonData['entries'] as Map<String, dynamic>;
      
      for (final MapEntry<String, dynamic> entry in entries.entries) {
        try {
          final CacheEntry cacheEntry = CacheEntry.fromJson(entry.value as Map<String, dynamic>);
          if (cacheEntry.isValid(_maxAge)) {
            _cache[entry.key] = cacheEntry;
          }
        } catch (e) {
          _logger.warning('Failed to load cache entry ${entry.key}: $e');
        }
      }
      
      _logger.info('Loaded ${_cache.length} valid cache entries from file');
    } catch (e) {
      _logger.warning('Failed to load cache from file: $e');
    }
  }

  /// Saves cache to file.
  Future<void> _saveToFile() async {
    if (_cacheFilePath == null) {
      return;
    }

    try {
      final File file = File(_cacheFilePath!);
      await file.parent.create(recursive: true);
      
      final Map<String, Object> cacheData = <String, Object>{
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'entries': _cache.map((String key, CacheEntry value) => MapEntry(key, value.toJson())),
      };
      
      await file.writeAsString(jsonEncode(cacheData));
      _logger.debug('Saved ${_cache.length} cache entries to file');
    } catch (e) {
      _logger.warning('Failed to save cache to file: $e');
    }
  }

  /// Disposes of the cache and saves to file if configured.
  Future<void> dispose() async {
    if (_cacheFilePath != null) {
      await _saveToFile();
    }
    _cache.clear();
  }
}
