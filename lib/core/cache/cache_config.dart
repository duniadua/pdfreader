/// Configuration constants for caching system
class CacheConfig {
  CacheConfig._();

  // LRU cache for PDF metadata (stores ~100 PDF objects in memory)
  static const int metadataCacheSize = 100;

  // Page cache per PDF (10 pages × ~500KB = ~5MB per open PDF)
  static const int pagesPerPdf = 10;
  static const int maxPageCacheSizeMb = 50;

  // Recent files to show and cache
  static const int recentCount = 10;

  // Pagination
  static const int initialPageSize = 20;
  static const int pageSize = 50;

  // Preload adjacent pages (current ± this many)
  static const int preloadRange = 2;

  // Reading progress debounce delay (milliseconds)
  static const int progressSaveDelayMs = 500;
}
