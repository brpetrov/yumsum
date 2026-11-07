import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lean_streak/core/constants/legal_links.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/providers/account_controller.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/language_provider.dart';
import 'package:lean_streak/providers/plus_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
import 'package:lean_streak/screens/account/account_settings_screen.dart';
import 'package:lean_streak/screens/plus/plus_screen.dart';
import 'package:lean_streak/widgets/legal_links.dart';

import 'adaptive_fixtures.dart';
import 'billing_fixtures.dart';

// The legal pages open in the app's language: /privacy-bg and /terms-bg in
// Bulgarian (tools/hosting/).

class _FakeAccountController extends AccountController {
  @override
  Future<void> syncAuthEmailToProfile() async {}
}

void main() {
  final opened = <String>[];

  setUp(() {
    opened.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          (call) async {
            if (call.method == 'launch') {
              opened.add((call.arguments as Map)['url'] as String);
            }
            return true;
          },
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/url_launcher'),
          null,
        );
  });

  /// [home] in [language], with what the account and YumSum Star pages read.
  Future<void> pump(WidgetTester tester, Widget home, String language) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          languageCodeProvider.overrideWithValue(language),
          currentUidProvider.overrideWithValue('user-1'),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(planProfile()),
          ),
          accountControllerProvider.overrideWith(_FakeAccountController.new),
          billingServiceProvider.overrideWithValue(FakeBillingService()),
          billingRepositoryProvider.overrideWithValue(FakeBillingRepository()),
          entitlementProvider.overrideWith((ref) => Stream.value(null)),
          realEntitlementProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: Locale(language),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('each page has an English and a Bulgarian address', () {
    expect(
      LegalLinks.privacyPolicy('en').toString(),
      'https://yumsum.web.app/privacy',
    );
    expect(LegalLinks.terms('en').toString(), 'https://yumsum.web.app/terms');
    expect(
      LegalLinks.privacyPolicy('bg').toString(),
      'https://yumsum.web.app/privacy-bg',
    );
    expect(
      LegalLinks.terms('bg').toString(),
      'https://yumsum.web.app/terms-bg',
    );
  });

  testWidgets('the sign-in footer opens the pages in English', (tester) async {
    await pump(tester, const Scaffold(body: LegalFooter()), 'en');

    await tester.tapOnText(find.textRange.ofSubstring('Terms of Use'));
    await tester.tapOnText(find.textRange.ofSubstring('Privacy Policy'));

    expect(opened, [
      'https://yumsum.web.app/terms',
      'https://yumsum.web.app/privacy',
    ]);
  });

  testWidgets('the sign-in footer opens the pages in Bulgarian', (
    tester,
  ) async {
    await pump(tester, const Scaffold(body: LegalFooter()), 'bg');

    await tester.tapOnText(find.textRange.ofSubstring('Условията за ползване'));
    await tester.tapOnText(
      find.textRange.ofSubstring('Политиката за поверителност'),
    );

    expect(opened, [
      'https://yumsum.web.app/terms-bg',
      'https://yumsum.web.app/privacy-bg',
    ]);
  });

  testWidgets('Account Settings opens the pages in Bulgarian', (tester) async {
    await pump(tester, const AccountSettingsScreen(), 'bg');

    final page = find.byType(Scrollable).first;
    for (final label in ['Политика за поверителност', 'Условия за ползване']) {
      await tester.scrollUntilVisible(find.text(label), 200, scrollable: page);
      await tester.tap(find.text(label));
    }

    expect(opened, [
      'https://yumsum.web.app/privacy-bg',
      'https://yumsum.web.app/terms-bg',
    ]);
  });

  testWidgets('YumSum Star opens the pages in Bulgarian', (tester) async {
    await pump(tester, const PlusScreen(), 'bg');

    for (final label in ['Условия', 'Поверителност']) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
    }

    expect(opened, [
      'https://yumsum.web.app/terms-bg',
      'https://yumsum.web.app/privacy-bg',
    ]);
  });
}
