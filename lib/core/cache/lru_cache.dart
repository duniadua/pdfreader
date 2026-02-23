import 'dart:collection';

/// Generic LRU (Least Recently Used) Cache implementation
///
/// Evicts the least recently used items when the cache reaches its maximum size.
/// Useful for caching PDF metadata and other frequently accessed data.
class LruCache<K, V> {
  LruCache({
    required this.maxSize,
    this.onEvict,
  }) : assert(maxSize > 0, 'maxSize must be positive'),
       _cache = LinkedHashMap<K, V>();

  /// Maximum number of items to store in cache
  final int maxSize;

  /// Optional callback called when an item is evicted from cache
  final void Function(K key, V value)? onEvict;

  final LinkedHashMap<K, V> _cache;
  int _hitCount = 0;
  int _missCount = 0;

  /// Get value from cache by key
  /// Returns null if key is not found
  V? get(K key) {
    final value = _cache[key];
    if (value != null) {
      // Move to end (most recently used)
      _cache.remove(key);
      _cache[key] = value;
      _hitCount++;
      return value;
    }
    _missCount++;
    return null;
  }

  /// Put value into cache
  /// If cache is full, evicts the least recently used item
  void put(K key, V value) {
    // Remove existing entry if present (will be re-added at end)
    _cache.remove(key);

    // Evict least recently used if at capacity
    if (_cache.length >= maxSize) {
      final lruKey = _cache.keys.first;
      final lruValue = _cache.remove(lruKey);
      onEvict?.call(lruKey, lruValue as V);
    }

    // Add new entry at end (most recently used)
    _cache[key] = value;
  }

  /// Check if key exists in cache
  bool containsKey(K key) => _cache.containsKey(key);

  /// Remove specific key from cache
  void invalidate(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      onEvict?.call(key, value);
    }
  }

  /// Clear all entries from cache
  void clear() {
    if (onEvict != null) {
      for (final entry in _cache.entries) {
        onEvict!.call(entry.key, entry.value);
      }
    }
    _cache.clear();
  }

  /// Get current number of items in cache
  int get size => _cache.length;

  /// Check if cache is empty
  bool get isEmpty => _cache.isEmpty;

  /// Check if cache is full
  bool get isFull => _cache.length >= maxSize;

  /// Get all keys in order (least recently used first)
  List<K> get keys => _cache.keys.toList();

  /// Get all values
  List<V> get values => _cache.values.toList();

  /// Get cache hit rate (0.0 to 1.0)
  double get hitRate {
    final total = _hitCount + _missCount;
    if (total == 0) return 0.0;
    return _hitCount / total;
  }

  /// Get cache statistics
  CacheStats get stats => CacheStats(
        size: size,
        maxSize: maxSize,
        hitCount: _hitCount,
        missCount: _missCount,
        hitRate: hitRate,
      );

  /// Reset statistics counters
  void resetStats() {
    _hitCount = 0;
    _missCount = 0;
  }
}

/// Cache statistics
class CacheStats {
  const CacheStats({
    required this.size,
    required this.maxSize,
    required this.hitCount,
    required this.missCount,
    required this.hitRate,
  });

  final int size;
  final int maxSize;
  final int hitCount;
  final int missCount;
  final double hitRate;

  @override
  String toString() =>
      'CacheStats(size: $size/$maxSize, hits: $hitCount, misses: $missCount, hitRate: ${(hitRate * 100).toStringAsFixed(1)}%)';
}
