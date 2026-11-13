/// The hosted legal pages (see tools/hosting/), in [language] ('en' or 'bg':
/// `languageCodeProvider`).
abstract final class LegalLinks {
  static Uri privacyPolicy(String language) => _page('privacy', language);
  static Uri terms(String language) => _page('terms', language);

  static Uri _page(String name, String language) =>
      Uri.parse('https://yumsum.app/$name${language == 'bg' ? '-bg' : ''}');

  /// Where the food data comes from; its licence asks for the credit.
  static final openFoodFacts = Uri.parse('https://world.openfoodfacts.org');
}
