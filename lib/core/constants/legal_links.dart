/// The hosted legal pages (see tools/hosting/).
abstract final class LegalLinks {
  static final privacyPolicy = Uri.parse(
    'https://lean-streak-project.web.app/privacy',
  );
  static final terms = Uri.parse('https://lean-streak-project.web.app/terms');

  /// Where the food data comes from; its licence asks for the credit.
  static final openFoodFacts = Uri.parse('https://world.openfoodfacts.org');
  static final feedback = Uri.parse(
    'mailto:broovenn@gmail.com?subject=LeanStreak%20feedback',
  );
}
