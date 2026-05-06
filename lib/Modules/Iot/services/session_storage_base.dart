abstract class SessionStorage {
  String? read(String key);
  void write(String key, String value);
  void remove(String key);
}
