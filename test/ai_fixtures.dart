import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';

/// The AI's Cloud Functions: keeps each call's name and data, and answers
/// with [reply], or throws [error] when it's set.
class FakeAiFunctions extends Fake implements FirebaseFunctions {
  final calls = <(String, Map<String, Object?>)>[];
  Object? reply = const <String, Object?>{};
  FirebaseFunctionsException? error;

  @override
  HttpsCallable httpsCallable(String name, {HttpsCallableOptions? options}) =>
      _FakeCallable(this, name);
}

class _FakeCallable extends Fake implements HttpsCallable {
  _FakeCallable(this._functions, this._name);

  final FakeAiFunctions _functions;
  final String _name;

  @override
  Future<HttpsCallableResult<T>> call<T>([dynamic parameters]) async {
    _functions.calls.add((_name, Map<String, Object?>.from(parameters as Map)));
    if (_functions.error case final error?) throw error;
    return _FakeResult<T>(_functions.reply as T);
  }
}

class _FakeResult<T> extends Fake implements HttpsCallableResult<T> {
  _FakeResult(this.data);

  @override
  final T data;
}

/// A server error as the app gets it.
FirebaseFunctionsException serverError(String code, [String? reason]) =>
    FirebaseFunctionsException(
      message: code,
      code: code,
      details: reason == null ? null : {'reason': reason},
    );
