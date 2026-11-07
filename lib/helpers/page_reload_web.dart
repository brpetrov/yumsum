import 'dart:js_interop';

@JS('location')
external _Location get _location;

extension type _Location(JSObject _) implements JSObject {
  external void reload();
}

void reloadPage() => _location.reload();
