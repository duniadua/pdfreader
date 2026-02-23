import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/models/pdf_document.dart';
import '../utils/logger.dart';
import 'cache_config.dart';
import 'lru_cache.dart';

/// Central cache manager for the application
///
/// Coordinates all caching operations including PDF metadata,
/// reading progress, and page caches.
class CacheManager {
  CacheManager._() {
    _initializeMetadataCache();
    _setupMemoryListener();
  }

  static CacheManager? _instance;
  static CacheManager get instance {
    _instance ??= CacheManager._();
    return _instance!;
  }

  // LRU Cache for PDF metadata
  late final LruCache<String, PdfDocument> _metadataCache;

  // In-memory cache for current reading positions
  final _readingProgressCache = <String, int>{};

  // Pending progress saves (debounced)
  final _pendingProgressSaves = <String, Timer>{};

  // Callback for saving progress to storage
  Future<void> Function(String documentId, int page, int scrollOffset)? _progressSaveCallback;

  void _initializeMetadataCache() {
    _metadataCache = LruCache<String, PdfDocument>(
      maxSize: CacheConfig.metadataCacheSize,
      onEvict: (key, value) {
        AppLogger.d('Evicted from cache: ${value.title}');
      },
    );
  }

  void _setupMemoryListener() {
    // Listen to memory pressure events
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      // TODO: Add memory pressure listener for mobile platforms
    }
  }

  /// Set the callback for persisting reading progress
  void setProgressSaveCallback(
    Future<void> Function(String documentId, int page, int scrollOffset) callback,
  ) {
    _progressSaveCallback = callback;
  }

  // ============ PDF Metadata Cache ============

  /// Get PDF document from cache
  PdfDocument? getPdfDocument(String id) {
    return _metadataCache.get(id);
  }

  /// Put PDF document into cache
  void cachePdfDocument(PdfDocument document) {
    _metadataCache.put(document.id, document);
  }

  /// Get multiple PDFs from cache (returns cached ones)
  List<PdfDocument> getPdfDocuments(List<String> ids) {
    final cached = <PdfDocument>[];
    final uncachedIds = <String>[];

    for (final id in ids) {
      final doc = _metadataCache.get(id);
      if (doc != null) {
        cached.add(doc);
      } else {
        uncachedIds.add(id);
      }
    }

    AppLogger.d('Cache hit: ${cached.length}/${ids.length}');
    return cached;
  }

  /// Cache multiple PDF documents
  void cachePdfDocuments(List<PdfDocument> documents) {
    for (final doc in documents) {
      _metadataCache.put(doc.id, doc);
    }
  }

  /// Invalidate a specific PDF from cache
  void invalidatePdf(String id) {
    _metadataCache.invalidate(id);
    _readingProgressCache.remove(id);
    _cancelPendingProgressSave(id);
  }

  /// Clear all PDF metadata from cache
  void clearMetadataCache() {
    _metadataCache.clear();
    _readingProgressCache.clear();
  }

  /// Get cache statistics
  CacheStats getMetadataCacheStats() => _metadataCache.stats;

  // ============ Reading Progress Cache ============

  /// Get current page for a document (from memory cache)
  int? getCurrentPage(String documentId) {
    return _readingProgressCache[documentId];
  }

  /// Update reading progress with debouncing
  Future<void> updateProgress(
    String documentId,
    int page,
    int scrollOffset,
  ) async {
    // Update in-memory cache immediately
    _readingProgressCache[documentId] = page;

    // Cancel any pending save for this document
    _cancelPendingProgressSave(documentId);

    // Schedule debounced save
    _pendingProgressSaves[documentId] = Timer(
      Duration(milliseconds: CacheConfig.progressSaveDelayMs),
      () async {
        await _persistProgress(documentId, page, scrollOffset);
        _pendingProgressSaves.remove(documentId);
      },
    );
  }

  /// Immediately save progress (bypasses debouncing)
  Future<void> saveProgressImmediately(
    String documentId,
    int page,
    int scrollOffset,
  ) async {
    _cancelPendingProgressSave(documentId);
    _readingProgressCache[documentId] = page;
    await _persistProgress(documentId, page, scrollOffset);
  }

  Future<void> _persistProgress(
    String documentId,
    int page,
    int scrollOffset,
  ) async {
    if (_progressSaveCallback == null) {
      AppLogger.w('Progress save callback not set');
      return;
    }

    try {
      await _progressSaveCallback!(documentId, page, scrollOffset);
    } catch (e, st) {
      AppLogger.e('Failed to save progress for $documentId', e, st);
    }
  }

  void _cancelPendingProgressSave(String documentId) {
    _pendingProgressSaves[documentId]?.cancel();
    _pendingProgressSaves.remove(documentId);
  }

  // ============ Lifecycle ============

  /// Flush all pending operations
  Future<void> flush() async {
    // Cancel all pending timers and save immediately
    final pendingSaves = Map<String, Timer>.from(_pendingProgressSaves);
    for (final entry in pendingSaves.entries) {
      entry.value.cancel();
      final page = _readingProgressCache[entry.key];
      if (page != null) {
        await _persistProgress(entry.key, page, 0);
      }
    }
    _pendingProgressSaves.clear();
  }

  /// Clear all caches
  Future<void> clearAll() async {
    await flush();
    clearMetadataCache();
  }

  /// Dispose of resources
  Future<void> dispose() async {
    await flush();
    for (final timer in _pendingProgressSaves.values) {
      timer.cancel();
    }
    _pendingProgressSaves.clear();
  }
}
