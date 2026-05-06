import 'session_storage_stub.dart'
    if (dart.library.html) 'session_storage_web.dart';
import 'session_storage_base.dart';

export 'session_storage_base.dart';

SessionStorage createSessionStorage() => createPlatformSessionStorage();
