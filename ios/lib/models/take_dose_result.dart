import 'dose_unit.dart';
import 'injection_site.dart';

enum DoseChangeScope { thisDoseOnly, thisAndFutureDoses }

class TakeDoseResult {
  const TakeDoseResult({
    required this.actualDoseAmount,
    required this.actualDoseUnit,
    required this.doseWasChanged,
    required this.changeScope,
    required this.injectionSite,
  });

  final double actualDoseAmount;
  final DoseUnit actualDoseUnit;

  /// True only when the confirmed amount or unit differs from the protocol.
  final bool doseWasChanged;

  /// Null when the dose was not changed.
  final DoseChangeScope? changeScope;

  /// Null for non-injection protocols or when rotation is disabled.
  final InjectionSite? injectionSite;

  bool get shouldUpdateFutureDoses {
    return doseWasChanged && changeScope == DoseChangeScope.thisAndFutureDoses;
  }

  String get formattedDose {
    return '${_formatAmount(actualDoseAmount)} ${actualDoseUnit.label}';
  }

  static String _formatAmount(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value
        .toStringAsFixed(3)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
