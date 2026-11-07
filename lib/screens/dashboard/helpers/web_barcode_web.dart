import 'dart:js_interop';

@JS('yumsumReadBarcode')
external JSPromise<JSString?> _readBarcode();

/// The barcode in the camera page's preview, or null, from
/// web/barcode_reader.js. Throws when no barcode reader could be loaded.
Future<String?> readWebBarcode() async => (await _readBarcode().toDart)?.toDart;
