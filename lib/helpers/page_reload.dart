/// Reloads the page on the web; does nothing elsewhere.
library;

export 'page_reload_stub.dart'
    if (dart.library.js_interop) 'page_reload_web.dart';
