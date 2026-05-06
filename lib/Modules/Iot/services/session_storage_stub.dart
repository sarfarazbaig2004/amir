import 'session_storage_base.dart';

class _MemorySessionStorage implements SessionStorage {
  final Map<String, String> _values = {};

  @override
  String? read(String key) => _values[key];

  @override
  void write(String key, String value) {
    _values[key] = value;
  }

  @override
  void remove(String key) {
    _values.remove(key);
  }
}

SessionStorage createPlatformSessionStorage() => _MemorySessionStorage();
