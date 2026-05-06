// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'session_storage_base.dart';

class _WebSessionStorage implements SessionStorage {
  @override
  String? read(String key) => html.window.localStorage[key];

  @override
  void write(String key, String value) {
    html.window.localStorage[key] = value;
  }

  @override
  void remove(String key) {
    html.window.localStorage.remove(key);
  }
}

SessionStorage createPlatformSessionStorage() => _WebSessionStorage();
