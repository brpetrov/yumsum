import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lean_streak/models/user_profile.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/repositories/user_profile_repository.dart';

/// Singleton repository backed by Firestore.
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository(FirebaseFirestore.instance);
});

/// Real-time stream of the current user's profile.
/// Emits null when unauthenticated or when the document does not exist yet.
final userProfileProvider = StreamProvider.autoDispose<UserProfile?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(userProfileRepositoryProvider).watchProfile(uid);
});

/// Whether protein is shown and estimated; on until the profile says not.
final trackProteinProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(
    userProfileProvider.select(
      (profile) => profile.valueOrNull?.trackProtein ?? true,
    ),
  );
});

/// Whether fat, carbs, salt and the rest are shown: with YumSum Star only.
/// They are saved for everyone, so upgrading shows the history as well.
final showMacrosProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(plusProvider);
});
