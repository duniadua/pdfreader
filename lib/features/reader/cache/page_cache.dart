import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../../../core/cache/cache_config.dart';
import '../../../../core/utils/logger.dart';

/// Cache key for a PDF page
class PageCacheKey {
  const PageCacheKey({
    required this.pdfId,
    required this.pageNumber,
    this.scale = 1.0,
  });

  final String pdfId;
  final int pageNumber;
  final double scale;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PageCacheKey &&
        other.pdfId == pdfId &&
        other.pageNumber == pageNumber &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(pdfId, pageNumber, scale);

  @override
  String toString() => 'PageCacheKey($pdfId, p$pageNumber, s$scale)';
}

/// Cache entry for a rendered PDF page
class PageCacheEntry {
  const PageCacheEntry({
    required this.imageData,
    required this.cachedAt,
    required this.pageNumber,
  });

  final Uint8List imageData;
  final DateTime cachedAt;
  final int pageNumber;

  /// Get size in bytes
  int get size => imageData.length;

  /// Check if entry is stale (older than 5 minutes)
  bool get isStale {
    const staleDuration = Duration(minutes: 5);
    return DateTime.now().difference(cachedAt) > staleDuration;
  }
}

/// PDF page cache with preloading support
///
/// Caches rendered PDF pages in memory for fast access.
/// Automatically preloads adjacent pages.
class PdfPageCache {
  PdfPageCache({
    required this.pdfId,
    int maxCachedPages = CacheConfig.pagesPerPdf,
  })  : _maxCachedPages = maxCachedPages,
        _cache = {};

  final String pdfId;
  final int _maxCachedPages;
  final Map<PageCacheKey, PageCacheEntry> _cache;

  int _totalSize = 0;
  int _maxSizeBytes = CacheConfig.maxPageCacheSizeMb * 1024 * 1024;

  /// Current page being viewed
  int _currentPage = 0;

  /// Get a cached page
  Uint8List? getPage(int pageNumber, {double scale = 1.0}) {
    final key = PageCacheKey(pdfId: pdfId, pageNumber: pageNumber, scale: scale);
    final entry = _cache[key];

    if (entry != null) {
      // Update access order by re-inserting
      _cache.remove(key);
      _cache[key] = entry;

      if (kDebugMode) {
        AppLogger.d('Cache HIT: $key');
      }
      return entry.imageData;
    }

    if (kDebugMode) {
      AppLogger.d('Cache MISS: $key');
    }
    return null;
  }

  /// Put a page into cache
  void putPage(int pageNumber, Uint8List imageData, {double scale = 1.0}) {
    final key = PageCacheKey(pdfId: pdfId, pageNumber: pageNumber, scale: scale);
    final entry = PageCacheEntry(
      imageData: imageData,
      cachedAt: DateTime.now(),
      pageNumber: pageNumber,
    );

    // Remove existing entry if present
    _cache.remove(key);
    _totalSize -= entry.size;

    // Evict oldest if at capacity
    _ensureCapacity(entry.size);

    // Add new entry
    _cache[key] = entry;
    _totalSize += entry.size;

    if (kDebugMode) {
      AppLogger.d('Cached: $key (${entry.size} bytes, ${_cache.length} items, ${(_totalSize / 1024 / 1024).toStringAsFixed(1)}MB)');
    }
  }

  /// Preload pages around the current page
  ///
  /// Loads pages in range [currentPage - preloadRange, currentPage + preloadRange]
  /// Returns the list of page numbers that should be preloaded
  List<int> getPagesToPreload(int currentPage, int totalPages) {
    _currentPage = currentPage;
    final pagesToPreload = <int>[];

    for (int i = -CacheConfig.preloadRange; i <= CacheConfig.preloadRange; i++) {
      final page = currentPage + i;
      if (page > 0 && page <= totalPages && page != currentPage) {
        // Only preload if not already cached
        final key = PageCacheKey(pdfId: pdfId, pageNumber: page);
        if (!_cache.containsKey(key)) {
          pagesToPreload.add(page);
        }
      }
    }

    return pagesToPreload;
  }

  /// Check if a page should be preloaded
  bool shouldPreload(int pageNumber) {
    final key = PageCacheKey(pdfId: pdfId, pageNumber: pageNumber);
    return !_cache.containsKey(key);
  }

  void _ensureCapacity(int incomingSize) {
    // Check count limit
    while (_cache.length >= _maxCachedPages) {
      _evictOldest();
    }

    // Check size limit
    while (_totalSize + incomingSize > _maxSizeBytes && _cache.isNotEmpty) {
      _evictOldest();
    }
  }

  void _evictOldest() {
    final oldestKey = _cache.keys.first;
    final oldestEntry = _cache.remove(oldestKey);
    if (oldestEntry != null) {
      _totalSize -= oldestEntry.size;
    }

    if (kDebugMode) {
      AppLogger.d('Evicted: $oldestKey');
    }
  }

  /// Clear all cached pages for this PDF
  void clear() {
    _cache.clear();
    _totalSize = 0;
  }

  /// Clear stale entries
  void clearStale() {
    final staleKeys = <PageCacheKey>[];
    for (final entry in _cache.entries) {
      if (entry.value.isStale) {
        staleKeys.add(entry.key);
      }
    }

    for (final key in staleKeys) {
      final entry = _cache.remove(key);
      if (entry != null) {
        _totalSize -= entry.size;
      }
    }

    if (staleKeys.isNotEmpty && kDebugMode) {
      AppLogger.d('Cleared ${staleKeys.length} stale entries');
    }
  }

  /// Get cache statistics
  PageCacheStats get stats => PageCacheStats(
        itemCount: _cache.length,
        totalSizeBytes: _totalSize,
        totalSizeMb: _totalSize / (1024 * 1024),
        maxSizeMb: _maxSizeBytes / (1024 * 1024),
        currentPage: _currentPage,
        maxPages: _maxCachedPages,
      );

  /// Update max size bytes
  void setMaxSizeBytes(int maxSizeBytes) {
    _maxSizeBytes = maxSizeBytes;
    _ensureCapacity(0);
  }
}

/// Page cache statistics
class PageCacheStats {
  const PageCacheStats({
    required this.itemCount,
    required this.totalSizeBytes,
    required this.totalSizeMb,
    required this.maxSizeMb,
    required this.currentPage,
    required this.maxPages,
  });

  final int itemCount;
  final int totalSizeBytes;
  final double totalSizeMb;
  final double maxSizeMb;
  final int currentPage;
  final int maxPages;

  @override
  String toString() =>
      'PageCacheStats($itemCount/$maxPages pages, ${totalSizeMb.toStringAsFixed(1)}MB/$maxSizeMb MB, current: $currentPage)';

  /// Get usage percentage
  double get usagePercentage => (totalSizeMb / maxSizeMb * 100).clamp(0, 100);
}
