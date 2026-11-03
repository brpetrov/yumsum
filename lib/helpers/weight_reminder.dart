/// The next [weekday] ([DateTime.monday] to [DateTime.sunday]) at
/// [hour]:[minute] local time strictly after [now]. Built with the DateTime
/// constructor rather than Duration arithmetic so the time of day survives
/// DST changes and month ends.
DateTime nextWeekdayAt({
  required int weekday,
  required int hour,
  required int minute,
  required DateTime now,
}) {
  final daysAhead = (weekday - now.weekday) % 7;
  var due = DateTime(now.year, now.month, now.day + daysAhead, hour, minute);
  if (!due.isAfter(now)) {
    due = DateTime(due.year, due.month, due.day + 7, hour, minute);
  }
  return due;
}

/// The next [hour]:[minute] local time strictly after [now]: today, or
/// tomorrow once it has passed.
DateTime nextDailyAt({
  required int hour,
  required int minute,
  required DateTime now,
}) {
  final today = DateTime(now.year, now.month, now.day, hour, minute);
  if (today.isAfter(now)) return today;
  return DateTime(now.year, now.month, now.day + 1, hour, minute);
}
