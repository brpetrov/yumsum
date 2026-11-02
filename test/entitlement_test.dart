import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/models/entitlement.dart';
import 'package:lean_streak/providers/debug_provider.dart';
import 'package:lean_streak/screens/plus/plus_screen.dart';

final _now = DateTime(2026, 11, 2, 12);
final _later = DateTime(2026, 12, 3);
final _earlier = DateTime(2026, 10, 30);

Entitlement _play({
  DateTime? expiresAt,
  String state = 'active',
  bool active = true,
  bool inTrial = false,
}) => Entitlement(
  active: active,
  source: EntitlementSource.play,
  expiresAt: expiresAt ?? _later,
  state: state,
  inTrial: inTrial,
);

void main() {
  test('a grant typed by hand needs only active and source', () {
    final grant = Entitlement.fromMap({'active': true, 'source': 'manual'});
    expect(grant.isPlusAt(_now), isTrue);
    expect(grant.endedAt(_now), isNull);
    expect(plusStatusLine(grant, _now), 'On');
    expect(managedInPlay(grant, _now), isFalse);
  });

  test('YumSum+ ends at expiresAt, which then counts as the end', () {
    final grant = Entitlement.fromMap({
      'active': true,
      'source': 'manual',
      'expiresAt': Timestamp.fromDate(_later),
    });
    expect(grant.isPlusAt(_now), isTrue);
    expect(plusStatusLine(grant, _now), 'On until 3 December');
    expect(grant.isPlusAt(_later), isFalse);
    expect(grant.endedAt(_later), _later);
  });

  test('a stored end wins, and an inactive record is off', () {
    final ended = Entitlement.fromMap({
      'active': false,
      'source': 'play',
      'state': 'expired',
      'expiresAt': Timestamp.fromDate(_later),
      'endedAt': Timestamp.fromDate(_earlier),
    });
    expect(ended.isPlusAt(_now), isFalse);
    expect(ended.endedAt(_now), _earlier);
    expect(
      plusStatusLine(ended, _now),
      'Photo logging, 30 AI estimates a day and more',
    );
    expect(managedInPlay(ended, _now), isFalse);
  });

  test('each Play state has its own line, managed in Google Play', () {
    expect(plusStatusLine(_play(), _now), 'Renews on 3 December');
    expect(
      plusStatusLine(_play(inTrial: true), _now),
      'Free trial until 3 December',
    );
    expect(
      plusStatusLine(_play(state: 'cancelled'), _now),
      'Ends on 3 December',
    );
    expect(
      plusStatusLine(_play(state: 'grace'), _now),
      'Payment problem. Fix it in Google Play to keep YumSum+.',
    );
    final hold = _play(state: 'hold', active: false);
    expect(
      plusStatusLine(hold, _now),
      'Off until the payment problem is fixed in Google Play',
    );
    expect(managedInPlay(_play(), _now), isTrue);
    expect(managedInPlay(hold, _now), isTrue);
  });

  test('no record means no YumSum+', () {
    expect(
      plusStatusLine(null, _now),
      'Photo logging, 30 AI estimates a day and more',
    );
    expect(managedInPlay(null, _now), isFalse);
  });

  test('admin is YumSum+ for good, whatever else the record says', () {
    final admin = Entitlement.fromMap({'admin': true});
    expect(admin.isPlusAt(_later), isTrue);
    expect(
      plusStatusLine(admin, _now),
      'Admin: everything on, no daily limits',
    );
    expect(managedInPlay(admin, _now), isFalse);
  });

  test('each pretend account in the debug tools is what it says', () {
    expect(DebugAccount.real.entitlementAt(_now), isNull);
    expect(DebugAccount.free.entitlementAt(_now), isNull);
    expect(DebugAccount.plus.entitlementAt(_now)!.isPlusAt(_now), isTrue);
    final trial = DebugAccount.trialEnding.entitlementAt(_now)!;
    expect(trial.inTrial, isTrue);
    expect(trial.isPlusAt(_now.add(const Duration(days: 3))), isFalse);
    final ended = DebugAccount.ended.entitlementAt(_now)!;
    expect(ended.isPlusAt(_now), isFalse);
    expect(ended.endedAt(_now), _now.subtract(const Duration(days: 3)));
    expect(DebugAccount.admin.entitlementAt(_now)!.admin, isTrue);
  });
}
