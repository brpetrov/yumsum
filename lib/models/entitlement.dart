import 'package:cloud_firestore/cloud_firestore.dart';

/// Who switched YumSum Star on: a Play subscription, or the owner by hand in
/// the Firebase console.
enum EntitlementSource {
  play('play'),
  manual('manual');

  const EntitlementSource(this.value);

  final String value;

  static EntitlementSource fromString(String? value) {
    return EntitlementSource.values.firstWhere(
      (item) => item.value == value,
      orElse: () => EntitlementSource.manual,
    );
  }
}

/// Whether an account has YumSum Star. Stored at `entitlements/{uid}`, which
/// only the server writes (the rules give the app read access alone), or
/// the owner by hand: a hand-typed grant may hold just `active`, `source`
/// and `expiresAt`, so every other field is optional. The owner's own
/// account also carries `admin` or `dev`.
class Entitlement {
  const Entitlement({
    required this.active,
    required this.source,
    this.expiresAt,
    this.inTrial = false,
    this.state,
    bool admin = false,
    this.dev = false,
    DateTime? endedAt,
  }) : _admin = admin,
       _endedAt = endedAt;

  final bool active;
  final EntitlementSource source;

  /// The end of the paid period or the trial; none for an open-ended grant.
  final DateTime? expiresAt;
  final bool inTrial;

  /// Play's state: `active`, `grace`, `cancelled`, `hold`, `paused`,
  /// `pending` or `expired`.
  final String? state;

  /// The owner: YumSum Star for good, and no daily AI or past-day limits.
  bool get admin => _admin || dev;
  final bool _admin;

  /// A developer: everything [admin] has, plus Debug tools in every build,
  /// the Play app and the website included.
  final bool dev;
  final DateTime? _endedAt;

  factory Entitlement.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) => Entitlement.fromMap(doc.data()!);

  factory Entitlement.fromMap(Map<String, dynamic> data) {
    DateTime? date(String field) => (data[field] as Timestamp?)?.toDate();
    return Entitlement(
      active: data['active'] == true,
      source: EntitlementSource.fromString(data['source'] as String?),
      expiresAt: date('expiresAt'),
      inTrial: data['inTrial'] == true,
      state: data['state'] as String?,
      admin: data['admin'] == true,
      dev: data['dev'] == true,
      endedAt: date('endedAt'),
    );
  }

  /// Checks the date on the device too, so a missed notice from Play can't
  /// leave YumSum Star on for ever.
  bool isPlusAt(DateTime now) =>
      admin || (active && (expiresAt == null || now.isBefore(expiresAt!)));

  /// When YumSum Star last switched off: the stored end, or [expiresAt] once it
  /// has passed (a missed notice from Play, or a grant that ran out).
  DateTime? endedAt(DateTime now) =>
      _endedAt ??
      (expiresAt != null && !now.isBefore(expiresAt!) ? expiresAt : null);
}
