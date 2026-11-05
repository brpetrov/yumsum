import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:lean_streak/models/meal.dart';

class MealRepository {
  MealRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _meals(String uid) =>
      _db.collection('users').doc(uid).collection('meals');

  /// Returns a new auto-generated document reference for a meal.
  /// Use this to get an ID before creating the [Meal] object.
  DocumentReference<Map<String, dynamic>> newMealRef(String uid) =>
      _meals(uid).doc();

  Future<void> addMeal(String uid, Meal meal) async {
    await _meals(uid).doc(meal.id).set(meal.toFirestore());
  }

  Future<void> updateMeal(String uid, Meal meal) async {
    await _meals(uid).doc(meal.id).set(meal.toFirestore());
  }

  Future<List<Meal>> fetchMealsForDate(String uid, String date) async {
    final snapshot = await _meals(uid).where('date', isEqualTo: date).get();
    final meals = snapshot.docs.map((doc) => Meal.fromFirestore(doc)).toList();
    meals.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return meals;
  }

  /// Streams all meals for [uid] on [date] (yyyy-MM-dd), ordered by timestamp.
  Stream<List<Meal>> watchMealsForDate(String uid, String date) {
    return _meals(uid).where('date', isEqualTo: date).snapshots().map((snap) {
      final meals = snap.docs.map((d) => Meal.fromFirestore(d)).toList();
      meals.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return meals;
    });
  }

  /// Meals on the days from [startDate] to [endDate] (yyyy-MM-dd), in date
  /// order and each day's in the order they were logged.
  Future<List<Meal>> fetchMealsInRange(
    String uid, {
    required String startDate,
    required String endDate,
  }) async {
    final snapshot = await _meals(uid)
        .where('date', isGreaterThanOrEqualTo: startDate)
        .where('date', isLessThanOrEqualTo: endDate)
        .orderBy('date')
        .get();
    final meals = snapshot.docs.map((doc) => Meal.fromFirestore(doc)).toList();
    meals.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : a.timestamp.compareTo(b.timestamp);
    });
    return meals;
  }

  /// Real-time stream of the latest [limit] meals logged, newest first;
  /// after the first read only changed meals are fetched again.
  Stream<List<Meal>> watchRecentMeals(String uid, {int limit = 120}) {
    return _meals(uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Meal.fromFirestore(doc)).toList(),
        );
  }

  Future<void> deleteMeal(String uid, String mealId) async {
    await _meals(uid).doc(mealId).delete();
  }
}
