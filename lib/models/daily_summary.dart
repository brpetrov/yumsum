import 'package:cloud_firestore/cloud_firestore.dart';

enum DailyStatus {
  green('green', 'On track'),
  yellow('yellow', 'Close'),
  red('red', 'Off track');

  const DailyStatus(this.value, this.label);

  final String value;
  final String label;

  static DailyStatus fromString(String value) {
    return DailyStatus.values.firstWhere((status) => status.value == value);
  }
}

class DailySummary {
  const DailySummary({
    required this.date,
    required this.totalCalories,
    required this.targetCalories,
    required this.calorieDelta,
    required this.mealCount,
    this.proteinGrams,
    required this.status,
    this.dayOff = false,
    required this.updatedAt,
  });

  final String date;
  final int totalCalories;
  final int targetCalories;
  final int calorieDelta;
  final int mealCount;

  /// Null when no meal that day had protein data.
  final int? proteinGrams;
  final DailyStatus status;

  /// Taken off (a holiday, a birthday): logged, but not judged.
  final bool dayOff;
  final DateTime updatedAt;

  double get deltaRatio {
    if (targetCalories <= 0) return 0;
    return calorieDelta.abs() / targetCalories;
  }

  factory DailySummary.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    return DailySummary(
      date: data['date'] as String,
      totalCalories: (data['totalCalories'] as num).round(),
      targetCalories: (data['targetCalories'] as num).round(),
      calorieDelta: (data['calorieDelta'] as num).round(),
      mealCount: data['mealCount'] as int,
      proteinGrams: (data['proteinGrams'] as num?)?.round(),
      status: _statusFromFirestore(data),
      dayOff: data['dayOff'] == true,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': date,
      'totalCalories': totalCalories,
      'targetCalories': targetCalories,
      'calorieDelta': calorieDelta,
      'mealCount': mealCount,
      if (proteinGrams != null) 'proteinGrams': proteinGrams,
      'status': status.value,
      if (dayOff) 'dayOff': true,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static DailyStatus _statusFromFirestore(Map<String, dynamic> data) {
    final storedStatus = data['status'] as String?;
    if (storedStatus != null) {
      return DailyStatus.fromString(storedStatus);
    }

    final targetCalories = (data['targetCalories'] as num?)?.round() ?? 0;
    final totalCalories = (data['totalCalories'] as num?)?.round() ?? 0;
    if (targetCalories <= 0) return DailyStatus.red;

    final ratio = (totalCalories - targetCalories).abs() / targetCalories;
    if (ratio <= 0.10) return DailyStatus.green;
    if (ratio <= 0.20) return DailyStatus.yellow;
    return DailyStatus.red;
  }
}
