import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/l10n/l10n.dart';
import 'package:lean_streak/models/nutrients.dart';
import 'package:lean_streak/providers/ai_usage_provider.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/country_provider.dart';
import 'package:lean_streak/providers/food_lookup_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/services/calorie_estimate_service.dart';
import 'package:lean_streak/services/food_contribution_service.dart';
import 'package:lean_streak/services/food_lookup_service.dart';

/// Offered when a scanned barcode isn't on Open Food Facts, or is there
/// without its nutrition ([nutritionOnly]). Adding it is put as what it
/// is: a small good turn for everyone who scans it next. True when the
/// user wants to contribute.
Future<bool> inviteToContribute(
  BuildContext context, {
  bool nutritionOnly = false,
}) async {
  final muted = TextStyle(
    fontSize: 15,
    height: 1.4,
    color: AppColors.textSecondary,
  );
  final l10n = context.l10n;
  final yes = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.volunteer_activism_outlined,
              size: 36,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              nutritionOnly
                  ? l10n.contributeAddNutritionTitle
                  : l10n.contributeAddProductTitle,
              textAlign: TextAlign.center,
              style: AppTheme.display.copyWith(
                fontSize: 20,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              nutritionOnly
                  ? l10n.contributeAddNutritionBody
                  : l10n.contributeAddProductBody,
              textAlign: TextAlign.center,
              style: muted,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.contributeTakesSeconds,
              textAlign: TextAlign.center,
              style: muted.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.favorite_rounded),
              label: Text(l10n.contributeButton),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.contributeNotNow),
            ),
          ],
        ),
      ),
    ),
  );
  return yes == true;
}

/// Whether the product reached Open Food Facts, and the product to log if
/// the user went on to Log it (they may close the thank-you instead).
typedef ContributionResult = ({bool contributed, PackagedFood? food});

/// Reads the label in [photos] (front, then nutrition table) with the AI,
/// lets the user check every figure, and sends the product to Open Food
/// Facts. For a product it [listed] without nutrition, [photos] is just
/// the table, and only what the product lacks is asked for and sent.
Future<ContributionResult> showContributeSheet(
  BuildContext context, {
  required String barcode,
  required List<XFile> photos,
  ListedProduct? listed,
}) async {
  var contributed = false;
  final food = await showModalBottomSheet<PackagedFood>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // A drag would close it even while sending; Back and a tap outside
    // still do when it isn't.
    enableDrag: false,
    backgroundColor: AppColors.surface,
    builder: (_) => _ContributeSheet(
      barcode: barcode,
      photos: photos,
      listed: listed,
      onContributed: () => contributed = true,
    ),
  );
  return (contributed: contributed, food: food);
}

/// The box label for each of [labelNutrientIds].
String _nutrientLabel(AppLocalizations l10n, String id) => switch (id) {
  'energy-kcal' => l10n.contributeEnergy,
  'proteins' => l10n.contributeProtein,
  'fat' => l10n.contributeFat,
  'saturated-fat' => l10n.contributeSaturates,
  'carbohydrates' => l10n.contributeCarbs,
  'sugars' => l10n.contributeSugars,
  'fiber' => l10n.contributeFibre,
  _ => l10n.contributeSalt,
};

class _ContributeSheet extends ConsumerStatefulWidget {
  const _ContributeSheet({
    required this.barcode,
    required this.photos,
    required this.listed,
    required this.onContributed,
  });

  final String barcode;
  final List<XFile> photos;
  final ListedProduct? listed;
  final VoidCallback onContributed;

  @override
  ConsumerState<_ContributeSheet> createState() => _ContributeSheetState();
}

class _ContributeSheetState extends ConsumerState<_ContributeSheet> {
  static const _countKey = 'contributions.count';

  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _quantity = TextEditingController();
  final _serving = TextEditingController();
  final _figures = {
    for (final id in labelNutrientIds) id: TextEditingController(),
  };

  List<Uint8List>? _images;
  bool _reading = true;
  bool _sending = false;
  String? _note;
  String? _error;
  int? _thanksCount;
  // The language the AI says the name is printed in.
  String? _lang;

  @override
  void initState() {
    super.initState();
    _read();
  }

  @override
  void dispose() {
    for (final box in [
      _name,
      _brand,
      _quantity,
      _serving,
      ..._figures.values,
    ]) {
      box.dispose();
    }
    super.dispose();
  }

  /// The AI fills the form; if it can't, the form is simply left empty.
  Future<void> _read() async {
    final images = [
      for (final photo in widget.photos) await photo.readAsBytes(),
    ];
    if (!mounted) return;
    setState(() => _images = images);
    final uid = ref.read(currentUidProvider);
    final l10n = context.l10n;
    try {
      if (uid == null) {
        throw CalorieEstimateException(l10n.contributeNotSignedIn);
      }
      final reading = await ref
          .read(calorieEstimateServiceProvider)
          .readLabel(uid, images.length > 1 ? images.first : null, images.last);
      if (!mounted) return;
      _name.text = reading.name ?? '';
      _brand.text = reading.brand ?? '';
      _quantity.text = reading.quantity ?? '';
      _serving.text = reading.servingSize ?? '';
      _lang = reading.lang;
      for (final MapEntry(:key, :value) in reading.per100g.entries) {
        _figures[key]?.text = _number(value, l10n);
      }
      _note = l10n.contributeAiRead(images.length);
    } on DailyLimitExceededException {
      _note = l10n.contributeAiLimit;
    } on CalorieEstimateException catch (error) {
      _note = error.message;
    } catch (_) {
      _note = l10n.contributeErrorRead;
    }
    if (mounted) setState(() => _reading = false);
  }

  /// [value] as typed: "2", "2,5" in Bulgarian, "0.25" in English.
  static String _number(double value, AppLocalizations l10n) {
    if (value == value.roundToDouble()) return '${value.round()}';
    final tenths = value * 10 == (value * 10).roundToDouble();
    return l10n.decimal(value, tenths ? 1 : 2);
  }

  double? _figure(String id) => parseDecimal(_figures[id]!.text);

  String? _text(TextEditingController box) {
    final text = box.text.trim();
    return text.isEmpty ? null : text;
  }

  // For a listed product, what it already has stands and isn't asked for.
  ListedProduct? get _listed => widget.listed;
  String? get _productName => _listed?.name ?? _text(_name);
  String? get _servingSize => _listed?.servingSize ?? _text(_serving);
  String? get _packSize =>
      _listed == null ? _text(_quantity) : _listed!.quantity;

  Future<void> _contribute() async {
    final name = _productName;
    final kcal = _figure('energy-kcal');
    if (name == null || kcal == null) {
      setState(() => _error = context.l10n.contributeErrorMissing);
      return;
    }
    final prefs = ref.read(sharedPreferencesProvider);
    final service = ref.read(foodContributionServiceProvider);
    final country = ref.read(countryProvider);
    final per100g = {for (final id in labelNutrientIds) id: ?_figure(id)};
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      if (_listed case final listed?) {
        await service.addNutrition((
          barcode: widget.barcode,
          lang: listed.lang ?? _lang ?? productLanguage(name),
          name: listed.name == null ? name : null,
          servingSize: listed.servingSize == null ? _text(_serving) : null,
          perVolume: soldByVolume(listed.quantity, _servingSize),
          per100g: per100g,
          labelPhoto: listed.hasNutritionPhoto ? null : _images!.last,
        ));
      } else {
        await service.contribute((
          barcode: widget.barcode,
          name: name,
          brand: _text(_brand),
          quantity: _text(_quantity),
          servingSize: _text(_serving),
          per100g: per100g,
          frontPhoto: _images![0],
          labelPhoto: _images![1],
          country: country,
          lang: _lang,
        ));
      }
    } on FoodContributionException catch (error) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = error.message;
        });
      }
      return;
    }
    widget.onContributed();
    final count = (prefs.getInt(_countKey) ?? 0) + 1;
    await prefs.setInt(_countKey, count);
    if (mounted) {
      setState(() {
        _sending = false;
        _thanksCount = count;
      });
    }
  }

  /// The product as just contributed, for the portion sheet.
  PackagedFood _food() {
    final protein = _figure('proteins');
    return (
      name: _productName!,
      brand: _listed == null ? _text(_brand) : _listed!.brand,
      kcalPer100g: _figure('energy-kcal')!.round(),
      proteinPer100g: protein?.round(),
      macrosPer100g: nutrientsFromOff({
        for (final id in labelNutrientIds) id: _figure(id),
      }),
      servingGrams: gramsIn(_servingSize),
      servingLabel: _servingSize,
      packGrams: gramsIn(_packSize),
      imageUrl: _listed?.imageUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_sending,
      child: Padding(
        // useSafeArea only guards the top of a sheet. padding.bottom is the
        // navigation bar and drops to 0 while the keyboard covers it.
        padding: EdgeInsets.only(
          bottom:
              MediaQuery.viewInsetsOf(context).bottom +
              MediaQuery.paddingOf(context).bottom,
        ),
        child: _thanksCount == null ? _buildForm() : _buildThanks(),
      ),
    );
  }

  Widget _buildThanks() {
    final count = _thanksCount!;
    final l10n = context.l10n;
    final product = _productName!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.favorite_rounded, size: 40, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            l10n.contributeThanks,
            textAlign: TextAlign.center,
            style: AppTheme.display.copyWith(
              fontSize: 22,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            [
              _listed == null
                  ? l10n.contributeThanksProduct(product)
                  : l10n.contributeThanksNutrition(product),
              if (count > 1) l10n.contributeThanksCount(count),
            ].join(' '),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_food()),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
            child: Text(l10n.contributeLogIt),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final muted = TextStyle(fontSize: 13, color: AppColors.textSecondary);
    final images = _images;
    final ids = labelNutrientIds;
    final listed = _listed;
    final l10n = context.l10n;

    Widget box(
      TextEditingController controller,
      String label, {
      bool number = false,
      String? key,
    }) => TextField(
      key: key == null ? null : ValueKey(key),
      controller: controller,
      enabled: !_reading && !_sending,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      inputFormatters: number
          ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
          : null,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(labelText: label),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            listed == null
                ? l10n.contributeCheckDetails
                : l10n.contributeCheckNutrition,
            style: AppTheme.display.copyWith(
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [?listed?.name, l10n.contributeBarcode(widget.barcode)].join(' · '),
            style: muted,
          ),
          const SizedBox(height: 12),
          if (images != null)
            Row(
              children: [
                for (final image in images) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      image,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          const SizedBox(height: 12),
          if (_reading)
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(l10n.contributeReading, style: muted),
              ],
            )
          else if (_note != null)
            Text(_note!, style: muted),
          const SizedBox(height: 16),
          if (listed == null) ...[
            box(_name, l10n.contributeProductName, key: 'contribute-name'),
            const SizedBox(height: 12),
            box(_brand, l10n.contributeBrand),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: box(_quantity, l10n.contributePackSize)),
                const SizedBox(width: 12),
                Expanded(child: box(_serving, l10n.contributeServing)),
              ],
            ),
            const SizedBox(height: 20),
          ] else ...[
            // Only what the product is missing besides its nutrition.
            if (listed.name == null) ...[
              box(_name, l10n.contributeProductName, key: 'contribute-name'),
              const SizedBox(height: 12),
            ],
            if (listed.servingSize == null) ...[
              box(_serving, l10n.contributeServing),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
          ],
          Text(
            l10n.contributePer100,
            style: muted.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < ids.length; i += 2) ...[
            Row(
              children: [
                for (final id in ids.skip(i).take(2)) ...[
                  Expanded(
                    child: box(
                      _figures[id]!,
                      _nutrientLabel(l10n, id),
                      number: true,
                      key: 'contribute-$id',
                    ),
                  ),
                  if (id == ids[i]) const SizedBox(width: 12),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          Text(
            listed == null
                ? l10n.contributePublishNew
                : listed.hasNutritionPhoto
                ? l10n.contributePublishFigures
                : l10n.contributePublishPhoto,
            style: muted,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(fontSize: 14, color: AppColors.error),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _reading || _sending ? null : _contribute,
            icon: _sending
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.onPrimary,
                    ),
                  )
                : const Icon(Icons.favorite_rounded),
            label: Text(l10n.contributeButton),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }
}
