import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/repositories/user_profile_repository.dart';

import 'adaptive_fixtures.dart';

/// Firestore with one document, `users/{uid}`, whose listener gives
/// [events].
class _FakeFirestore extends Fake implements FirebaseFirestore {
  _FakeFirestore(this.events);

  final List<_Snapshot> events;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _FakeUsers(events);
}

// ignore: subtype_of_sealed_class
class _FakeUsers extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _FakeUsers(this.events);

  final List<_Snapshot> events;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _FakeDoc(events);
}

// ignore: subtype_of_sealed_class
class _FakeDoc extends Fake implements DocumentReference<Map<String, dynamic>> {
  _FakeDoc(this.events);

  final List<_Snapshot> events;

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) => Stream.fromIterable(events);
}

// ignore: subtype_of_sealed_class
/// [data] null: the document doesn't exist.
class _Snapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  _Snapshot(this._data, {bool fromCache = false, bool pending = false})
    : metadata = _Metadata(fromCache, pending);

  final Map<String, dynamic>? _data;

  @override
  final SnapshotMetadata metadata;

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic>? data() => _data;
}

class _Metadata extends Fake implements SnapshotMetadata {
  _Metadata(this.isFromCache, this.hasPendingWrites);

  @override
  final bool isFromCache;

  @override
  final bool hasPendingWrites;
}

void main() {
  Future<List<String?>> names(List<_Snapshot> snapshots) =>
      UserProfileRepository(
        _FakeFirestore(snapshots),
      ).watchProfile('user-1').map((profile) => profile?.name).toList();

  // Fresh maps each time, as each snapshot gives, with a list of maps in.
  Map<String, dynamic> data({String name = 'Test'}) => planProfile()
      .copyWith(
        name: name,
        adaptiveChanges: [(week: '2026-10-26', from: 1670, to: 1590)],
      )
      .toFirestore();

  test('none in the cache waits for the server, which says none', () async {
    expect(await names([_Snapshot(null, fromCache: true), _Snapshot(null)]), [
      null,
    ]);
  });

  test('the same profile again with new metadata is not emitted', () async {
    expect(
      await names([
        _Snapshot(data(), fromCache: true),
        _Snapshot(data()),
        _Snapshot(data(name: 'New'), pending: true),
        _Snapshot(data(name: 'New')),
      ]),
      ['Test', 'New'],
    );
  });

  test('a profile that goes is emitted as none', () async {
    expect(await names([_Snapshot(data()), _Snapshot(null)]), ['Test', null]);
  });
}
