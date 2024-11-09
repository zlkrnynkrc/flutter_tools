// Cache implementasyonu
class CacheEntry<T> {
  final T value;
  final DateTime expiresAt;

  CacheEntry(this.value, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class Cache<T> {
  final Map<String, CacheEntry<T>> _cache = {};
  final Duration defaultTtl;
  final int? maxSize;

  Cache({
    this.defaultTtl = const Duration(minutes: 5),
    this.maxSize,
  });

  T? get(String key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.value;
  }

  void set(String key, T value, [Duration? ttl]) {
    if (maxSize != null &&
        _cache.length >= maxSize! &&
        !_cache.containsKey(key)) {
      _cache.remove(_cache.keys.first); // Simple LRU implementation
    }

    _cache[key] = CacheEntry(
      value,
      DateTime.now().add(ttl ?? defaultTtl),
    );
  }

  void clear() => _cache.clear();

  int get size => _cache.length;
}
