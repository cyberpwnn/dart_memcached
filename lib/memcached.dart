library memcached;

import 'package:synchronized/synchronized.dart';

typedef ValueGetter<T> = T Function();

Map<String, Lock> cacheLocks = {};
Map<String, LazyCache<dynamic>> _lazyCaches = {};
Map<String, LazyCacheSync<dynamic>> _lazyCachesSync = {};

Lock getLock(String key) {
  if (!cacheLocks.containsKey(key)) {
    cacheLocks[key] = Lock(reentrant: true);
  }

  return cacheLocks[key]!;
}

void invalidateCached(String id) =>
    getLock(id).synchronized(() => _lazyCaches.remove(id));

void invalidateCachedSync(String id) => _lazyCachesSync.remove(id);

Future<T> getCached<T>(
        {required String id,
        required ValueGetter<Future<T>> getter,
        required Duration duration}) =>
    getLock(id).synchronized(() {
      LazyCache<T> c = (_lazyCaches.containsKey(id)
          ? _lazyCaches[id] as LazyCache<T>
          : LazyCache<T>(id: id, getter: getter, duration: duration));
      _lazyCaches[id] = c;
      return c.get();
    });

T getCachedSync<T>(
    {required String id,
    required ValueGetter<T> getter,
    required Duration duration}) {
  LazyCacheSync<T> c = (_lazyCachesSync.containsKey(id)
      ? _lazyCachesSync[id] as LazyCacheSync<T>
      : LazyCacheSync<T>(id: id, getter: getter, duration: duration));
  _lazyCachesSync[id] = c;
  return c.get();
}

class LazyCacheSync<T> {
  final String id;
  final Duration duration;
  final ValueGetter<T> getter;
  T? _last;
  int _lastGet = 0;

  LazyCacheSync(
      {required this.id, required this.getter, required this.duration});

  T get() {
    if (DateTime.now().millisecondsSinceEpoch - _lastGet >
        duration.inMilliseconds) {
      _last = null;
      _lastGet = DateTime.now().millisecondsSinceEpoch;
    }

    _last ??= getter();
    return _last!;
  }
}

class LazyCache<T> {
  final String id;
  final Duration duration;
  final ValueGetter<Future<T>> getter;
  Future<T>? _last;
  int _lastGet = 0;

  LazyCache({required this.id, required this.getter, required this.duration});

  Future<T> get() async {
    if (DateTime.now().millisecondsSinceEpoch - _lastGet >
        duration.inMilliseconds) {
      _last = null;
      _lastGet = DateTime.now().millisecondsSinceEpoch;
    }

    _last ??= getter();
    return _last!;
  }
}
