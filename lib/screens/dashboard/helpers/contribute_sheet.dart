import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/core/theme/app_theme.dart';
import 'package:lean_streak/providers/ai_usage_provider.dart';
import 'package:lean_streak/providers/auth_provider.dart';
import 'package:lean_streak/providers/food_lookup_provider.dart';
import 'package:lean_streak/providers/preferences_provider.dart';
import 'package:lean_streak/providers/user_profile_provider.dart';
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
              nutritionOnly ? 'Add its nutrition' : 'Be the first to add this',
              textAlign: TextAlign.center,
              style: AppTheme.display.copyWith(
                fontSize: 20,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              nutritionOnly
                  ? 'This product is in the database, but its nutrition '
                        'isn\'t yet. Add it with one photo of the nutrition '
                        'table and it\'ll be there for you and everyone who '
                        'scans it next.'
                  : 'This product isn\'t in the database yet. Add it with '
                        'two photos and it\'ll be there for you and everyone '
                        'who scans it next.',
              textAlign: TextAlign.center,
              style: muted,
            ),
            const SizedBox(height: 6),
            Text(
              'It takes 30 seconds and helps everyone, forever ♥',
              textAlign: TextAlign.center,
              style: muted.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.favorite_rounded),
              label: const Text('Contribute'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
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

const _nutrientLabels = {
  'energy-kcal': 'Energy (kcal)',
  'proteins': 'Protein (g)',
  'fat': 'Fat (g)',
  'saturated-fat': 'of which saturates (g)',
  'carbohydrates': 'Carbohydrate (g)',
  'sugars': 'of which sugars (g)',
  'fiber': 'Fibre (g)',
  'salt': 'Salt (g)',
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
    try {
      if (uid == null) throw const CalorieEstimateException('Not signed in.');
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
        _figures[key]?.text = _number(value);
      }
      _note =
          'The AI read these from your '
          '${images.length > 1 ? 'photos' : 'photo'}. Check them against '
          'the packet: they will be public.';
    } on DailyLimitExceededException {
      _note =
          'Daily AI limit reached. Copy the details from the packet '
          'yourself.';
    } on CalorieEstimateException catch (error) {
      _note = error.message;
    } catch (_) {
      _note = 'Could not read the label. Fill in the details yourself.';
    }
    if (mounted) setState(() => _reading = false);
  }

  static String _number(double value) =>
      value == value.roundToDouble() ? '${value.round()}' : '$value';

  double? _figure(String id) =>
      double.tryParse(_figures[id]!.text.trim().replaceAll(',', '.'));

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
      setState(() => _error = 'Add the product name and energy (kcal).');
      return;
    }
    final prefs = ref.read(sharedPreferencesProvider);
    final service = ref.read(foodContributionServiceProvider);
    final country = ref.read(userProfileProvider).valueOrNull?.country;
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
      servingGrams: gramsIn(_servingSize) ?? gramsIn(_packSize),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.favorite_rounded, size: 40, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            'Thank you!',
            textAlign: TextAlign.center,
            style: AppTheme.display.copyWith(
              fontSize: 22,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_productName ${_listed == null ? 'is now on' : 'now has its nutrition on'} '
            'Open Food Facts for everyone who scans it next.'
            '${count > 1 ? ' That\'s $count products you\'ve added.' : ''}',
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
            child: const Text('Log it'),
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
            listed == null ? 'Check the details' : 'Check the nutrition',
            style: AppTheme.display.copyWith(
              fontSize: 20,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [?listed?.name, 'Barcode ${widget.barcode}'].join(' · '),
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
                Text('Reading the label...', style: muted),
              ],
            )
          else if (_note != null)
            Text(_note!, style: muted),
          const SizedBox(height: 16),
          if (listed == null) ...[
            box(_name, 'Product name', key: 'contribute-name'),
            const SizedBox(height: 12),
            box(_brand, 'Brand'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: box(_quantity, 'Pack size, e.g. 400 g')),
                const SizedBox(width: 12),
                Expanded(child: box(_serving, 'Serving, e.g. 30 g')),
              ],
            ),
            const SizedBox(height: 20),
          ] else ...[
            // Only what the product is missing besides its nutrition.
            if (listed.name == null) ...[
              box(_name, 'Product name', key: 'contribute-name'),
              const SizedBox(height: 12),
            ],
            if (listed.servingSize == null) ...[
              box(_serving, 'Serving, e.g. 30 g'),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
          ],
          Text(
            'PER 100 G (OR 100 ML)',
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
                      _nutrientLabels[id]!,
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
            '${listed == null
                ? 'Your photos and these details'
                : listed.hasNutritionPhoto
                ? 'These figures'
                : 'Your photo and these figures'} will be published on Open '
            'Food Facts under open licences (CC BY-SA and ODbL), so anyone '
            'can use them. Your name and email are never shared.',
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
            label: const Text('Contribute'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }
}
