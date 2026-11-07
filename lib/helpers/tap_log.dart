import 'package:flutter/foundation.dart';

/// Temporary, to see what iOS Safari does to the quick-log chips: on the
/// web, opening the app with `?debugtaps` shows a log of touches on the
/// quick-log panel and the boxes' focus over the bar. Null otherwise.
final ValueNotifier<List<String>>? tapLog =
    kIsWeb && Uri.base.queryParameters.containsKey('debugtaps')
    ? ValueNotifier(const [])
    : null;

void logTap(String event) {
  final log = tapLog;
  if (log == null) return;
  final now = DateTime.now();
  final at =
      '${now.second.toString().padLeft(2, '0')}.'
      '${now.millisecond.toString().padLeft(3, '0')}';
  log.value = [
    ...log.value,
    '$at $event',
  ].reversed.take(8).toList().reversed.toList();
}
