import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cloud Functions that keep each call and throw [error] when it's set.
class FakeFunctions extends Fake implements FirebaseFunctions {
  final calls = <({String name, Object? data, Duration? timeout})>[];
  Object? error;

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) =>
      _Callable(this, name, options?.timeout);
}

class _Callable extends Fake implements HttpsCallable {
  _Callable(this._functions, this._name, this._timeout);
  final FakeFunctions _functions;
  final String _name;
  final Duration? _timeout;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    _functions.calls.add((name: _name, data: parameters, timeout: _timeout));
    if (_functions.error case final error?) throw error;
    return _Result<T>();
  }
}

class _Result<T> extends Fake implements HttpsCallableResult<T> {}
