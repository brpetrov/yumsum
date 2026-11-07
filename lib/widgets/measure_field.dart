import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lean_streak/core/constants/app_colors.dart';
import 'package:lean_streak/models/units.dart';
import 'package:lean_streak/widgets/pill_toggle.dart';

/// What's typed for a weight or height in the user's unit: one box, or two
/// for stones and pounds or feet and inches. [value] is in kg or cm, and a
/// value put in with [show] comes back exactly until a box is edited, so a
/// form saved untouched changes nothing.
abstract class MeasureInput {
  final whole = TextEditingController();
  final part = TextEditingController();
  double? _shown;
  String _shownWhole = '';
  String _shownPart = '';

  bool get twoBoxes;
  String get wholeSuffix;
  String get partLabel;
  String get partSuffix;
  int get wholeDigits;

  /// The boxes' text for [value].
  (String, String) texts(double value);

  /// The value in the boxes, or null when it isn't a number.
  double? parse(double? whole, double? part);

  bool get isEmpty => whole.text.trim().isEmpty && part.text.trim().isEmpty;

  double? get value {
    if (_shown != null &&
        whole.text == _shownWhole &&
        part.text == _shownPart) {
      return _shown;
    }
    double? read(TextEditingController box) =>
        double.tryParse(box.text.trim().replaceAll(',', '.'));
    if (!twoBoxes) return parse(read(whole), null);
    if (isEmpty) return null;
    // An empty box of the two counts as nought: "12" st, "" lb.
    final w = whole.text.trim().isEmpty ? 0.0 : read(whole);
    final p = part.text.trim().isEmpty ? 0.0 : read(part);
    if (w == null || p == null) return null;
    return parse(w, p);
  }

  void show(double? value) {
    _shown = value;
    final (w, p) = value == null ? ('', '') : texts(value);
    whole.text = _shownWhole = w;
    part.text = _shownPart = p;
  }

  void dispose() {
    whole.dispose();
    part.dispose();
  }
}

/// One decimal at most, and none when it's a whole number.
String _number(double value) {
  final rounded = (value * 10).round() / 10;
  return rounded == rounded.roundToDouble()
      ? rounded.round().toString()
      : rounded.toStringAsFixed(1);
}

/// A whole and a part (stones and pounds, feet and inches) for [small]
/// units with [perWhole] to the whole, to one decimal.
(String, String) _split(double small, int perWhole) {
  final total = (small * 10).round() / 10;
  final whole = total ~/ perWhole;
  return (whole.toString(), _number(total - whole * perWhole));
}

class WeightInput extends MeasureInput {
  WeightInput(this.unit);

  WeightUnit unit;

  /// Shows the same weight in [next].
  void switchTo(WeightUnit next) {
    if (next == unit) return;
    final kg = value;
    unit = next;
    show(kg);
  }

  @override
  bool get twoBoxes => unit == WeightUnit.st;
  @override
  String get wholeSuffix => unit.value;
  @override
  String get partLabel => 'Pounds';
  @override
  String get partSuffix => 'lb';
  @override
  int get wholeDigits => twoBoxes ? 2 : 3;

  @override
  (String, String) texts(double value) => switch (unit) {
    WeightUnit.kg => (_number(value), ''),
    WeightUnit.lb => (_number(kgToLb(value)), ''),
    WeightUnit.st => _split(kgToLb(value), 14),
  };

  @override
  double? parse(double? whole, double? part) {
    if (whole == null) return null;
    return switch (unit) {
      WeightUnit.kg => whole,
      WeightUnit.lb => lbToKg(whole),
      WeightUnit.st => lbToKg(whole * 14 + (part ?? 0)),
    };
  }
}

class HeightInput extends MeasureInput {
  HeightInput(this.unit);

  HeightUnit unit;

  /// Shows the same height in [next].
  void switchTo(HeightUnit next) {
    if (next == unit) return;
    final cm = value;
    unit = next;
    show(cm);
  }

  @override
  bool get twoBoxes => unit == HeightUnit.ftin;
  @override
  String get wholeSuffix => twoBoxes ? 'ft' : 'cm';
  @override
  String get partLabel => 'Inches';
  @override
  String get partSuffix => 'in';
  @override
  int get wholeDigits => twoBoxes ? 1 : 3;

  @override
  (String, String) texts(double value) => switch (unit) {
    HeightUnit.cm => (_number(value), ''),
    HeightUnit.ftin => _split(value / cmPerInch, 12),
  };

  @override
  double? parse(double? whole, double? part) {
    if (whole == null) return null;
    return switch (unit) {
      HeightUnit.cm => whole,
      HeightUnit.ftin => (whole * 12 + (part ?? 0)) * cmPerInch,
    };
  }
}

/// The boxes for a [MeasureInput], with what's wrong under them: [error]
/// where the page works it out itself, or [validator] inside a Form.
class MeasureField extends StatelessWidget {
  const MeasureField({
    super.key,
    required this.input,
    required this.label,
    this.error,
    this.validator,
    this.autofocus = false,
    this.prefixIcon,
    this.textInputAction = TextInputAction.next,
    this.onChanged,
    this.onSubmitted,
  });

  final MeasureInput input;
  final String label;
  final String? error;
  final String? Function()? validator;
  final bool autofocus;
  final Widget? prefixIcon;
  final TextInputAction textInputAction;
  final VoidCallback? onChanged;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return FormField<void>(
      validator: validator == null ? null : (_) => validator!(),
      builder: (field) {
        final message = error ?? field.errorText;
        void changed(String _) {
          field.didChange(null);
          onChanged?.call();
        }

        const keyboard = TextInputType.numberWithOptions(decimal: true);
        final whole = TextField(
          controller: input.whole,
          autofocus: autofocus,
          keyboardType: input.twoBoxes ? TextInputType.number : keyboard,
          textInputAction: input.twoBoxes
              ? TextInputAction.next
              : textInputAction,
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(
                input.twoBoxes
                    ? '^\\d{0,${input.wholeDigits}}'
                    : r'^\d{0,3}[.,]?\d{0,1}',
              ),
            ),
          ],
          decoration: InputDecoration(
            labelText: label,
            suffixText: input.wholeSuffix,
            // No room for it beside a second box.
            prefixIcon: input.twoBoxes ? null : prefixIcon,
            errorText: input.twoBoxes ? null : message,
          ),
          onChanged: changed,
          onSubmitted: input.twoBoxes || onSubmitted == null
              ? null
              : (_) => onSubmitted!(),
        );
        if (!input.twoBoxes) return whole;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: whole),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: input.part,
                    keyboardType: keyboard,
                    textInputAction: textInputAction,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d{0,2}[.,]?\d{0,1}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: input.partLabel,
                      suffixText: input.partSuffix,
                    ),
                    onChanged: changed,
                    onSubmitted: onSubmitted == null
                        ? null
                        : (_) => onSubmitted!(),
                  ),
                ),
              ],
            ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: Text(
                  message,
                  style: TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// kg, lb, or stones and pounds.
class WeightUnitToggle extends StatelessWidget {
  const WeightUnitToggle({
    super.key,
    required this.unit,
    required this.onChanged,
  });

  final WeightUnit unit;
  final ValueChanged<WeightUnit> onChanged;

  @override
  Widget build(BuildContext context) => PillToggle<WeightUnit>(
    options: const [
      (WeightUnit.kg, 'kg'),
      (WeightUnit.lb, 'lb'),
      (WeightUnit.st, 'st & lb'),
    ],
    selected: unit,
    onChanged: onChanged,
  );
}

/// cm, or feet and inches.
class HeightUnitToggle extends StatelessWidget {
  const HeightUnitToggle({
    super.key,
    required this.unit,
    required this.onChanged,
  });

  final HeightUnit unit;
  final ValueChanged<HeightUnit> onChanged;

  @override
  Widget build(BuildContext context) => PillToggle<HeightUnit>(
    options: const [(HeightUnit.cm, 'cm'), (HeightUnit.ftin, 'ft & in')],
    selected: unit,
    onChanged: onChanged,
  );
}
