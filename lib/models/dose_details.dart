import 'dart:convert';

import 'dose_unit.dart';

enum DoseForm {
  tablet,
  capsule,
  pill,
  liquid,
  powder,
  cream,
  gel,
  patch,
  spray,
  drop,
  pump,
  scoop,
  serving,
  injection,
  other,
}

extension DoseFormDetails on DoseForm {
  String get label {
    return switch (this) {
      DoseForm.tablet => 'Tablet',
      DoseForm.capsule => 'Capsule',
      DoseForm.pill => 'Pill',
      DoseForm.liquid => 'Liquid',
      DoseForm.powder => 'Powder',
      DoseForm.cream => 'Cream',
      DoseForm.gel => 'Gel',
      DoseForm.patch => 'Patch',
      DoseForm.spray => 'Spray',
      DoseForm.drop => 'Drop',
      DoseForm.pump => 'Pump',
      DoseForm.scoop => 'Scoop',
      DoseForm.serving => 'Serving',
      DoseForm.injection => 'Injection',
      DoseForm.other => 'Other',
    };
  }

  String get storageValue => name;

  static DoseForm? fromStorageValue(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    for (final form in DoseForm.values) {
      if (form.name == value.trim().toLowerCase()) return form;
    }

    return null;
  }
}

class BlendComponent {
  const BlendComponent({
    required this.name,
    required this.amount,
    required this.unit,
  });

  final String name;
  final double amount;
  final DoseUnit unit;

  Map<String, Object?> toMap() => {
    'name': name,
    'amount': amount,
    'unit': unit.storageValue,
  };

  factory BlendComponent.fromMap(Map<String, Object?> map) {
    return BlendComponent(
      name: map['name'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      unit: DoseUnitDetails.fromStorageValue(map['unit'] as String?),
    );
  }
}

class DoseDetails {
  const DoseDetails({
    this.form,
    this.strengthAmount,
    this.strengthUnit,
    this.scheduledQuantity,
    this.vialAmount,
    this.vialUnit,
    this.reconstitutionVolumeMl,
    this.syringeType = 'U-100',
    this.showDrawUnitsOnCards = false,
    this.blendComponents = const [],
  });

  final DoseForm? form;
  final double? strengthAmount;
  final DoseUnit? strengthUnit;
  final double? scheduledQuantity;
  final double? vialAmount;
  final DoseUnit? vialUnit;
  final double? reconstitutionVolumeMl;
  final String syringeType;
  final bool showDrawUnitsOnCards;
  final List<BlendComponent> blendComponents;

  bool get hasOralStrength =>
      form != null &&
      strengthAmount != null &&
      strengthAmount! > 0 &&
      strengthUnit != null &&
      scheduledQuantity != null &&
      scheduledQuantity! > 0;

  double? get totalActiveDose =>
      hasOralStrength ? strengthAmount! * scheduledQuantity! : null;

  bool get hasReconstitution =>
      vialAmount != null &&
      vialAmount! > 0 &&
      vialUnit != null &&
      reconstitutionVolumeMl != null &&
      reconstitutionVolumeMl! > 0;

  double? concentrationPerMl({required DoseUnit scheduledDoseUnit}) {
    if (!hasReconstitution) return null;

    final vialInScheduledUnit = _convertAmount(
      vialAmount!,
      from: vialUnit!,
      to: scheduledDoseUnit,
    );

    if (vialInScheduledUnit == null) return null;
    return vialInScheduledUnit / reconstitutionVolumeMl!;
  }

  double? drawMl({
    required double scheduledDoseAmount,
    required DoseUnit scheduledDoseUnit,
  }) {
    final concentration = concentrationPerMl(
      scheduledDoseUnit: scheduledDoseUnit,
    );

    if (concentration == null || concentration <= 0) return null;
    return scheduledDoseAmount / concentration;
  }

  double? drawUnits({
    required double scheduledDoseAmount,
    required DoseUnit scheduledDoseUnit,
  }) {
    final ml = drawMl(
      scheduledDoseAmount: scheduledDoseAmount,
      scheduledDoseUnit: scheduledDoseUnit,
    );

    if (ml == null || syringeType != 'U-100') return null;
    return ml * 100;
  }

  bool get hasPhysicalDose =>
      form != null &&
      form != DoseForm.injection &&
      strengthAmount != null &&
      strengthAmount! > 0 &&
      strengthUnit != null &&
      scheduledQuantity != null &&
      scheduledQuantity! > 0;

  String get quantityUnitLabel {
    return switch (form) {
      DoseForm.tablet => 'tablet',
      DoseForm.capsule => 'capsule',
      DoseForm.pill => 'pill',
      DoseForm.liquid => 'mL',
      DoseForm.powder => 'g',
      DoseForm.cream => 'mL',
      DoseForm.gel => 'mL',
      DoseForm.patch => 'patch',
      DoseForm.spray => 'spray',
      DoseForm.drop => 'drop',
      DoseForm.pump => 'pump',
      DoseForm.scoop => 'scoop',
      DoseForm.serving => 'serving',
      _ => 'dose',
    };
  }

  DoseDetails copyWith({
    DoseForm? form,
    double? strengthAmount,
    DoseUnit? strengthUnit,
    double? scheduledQuantity,
    double? vialAmount,
    DoseUnit? vialUnit,
    double? reconstitutionVolumeMl,
    String? syringeType,
    bool? showDrawUnitsOnCards,
    List<BlendComponent>? blendComponents,
  }) {
    return DoseDetails(
      form: form ?? this.form,
      strengthAmount: strengthAmount ?? this.strengthAmount,
      strengthUnit: strengthUnit ?? this.strengthUnit,
      scheduledQuantity: scheduledQuantity ?? this.scheduledQuantity,
      vialAmount: vialAmount ?? this.vialAmount,
      vialUnit: vialUnit ?? this.vialUnit,
      reconstitutionVolumeMl:
          reconstitutionVolumeMl ?? this.reconstitutionVolumeMl,
      syringeType: syringeType ?? this.syringeType,
      showDrawUnitsOnCards: showDrawUnitsOnCards ?? this.showDrawUnitsOnCards,
      blendComponents: blendComponents ?? this.blendComponents,
    );
  }

  Map<String, Object?> toMap() => {
    'form': form?.storageValue,
    'strength_amount': strengthAmount,
    'strength_unit': strengthUnit?.storageValue,
    'scheduled_quantity': scheduledQuantity,
    'vial_amount': vialAmount,
    'vial_unit': vialUnit?.storageValue,
    'reconstitution_volume_ml': reconstitutionVolumeMl,
    'syringe_type': syringeType,
    'show_draw_units_on_cards': showDrawUnitsOnCards,
    'blend_components': blendComponents
        .map((component) => component.toMap())
        .toList(),
  };

  factory DoseDetails.fromMap(Map<String, Object?> map) {
    final rawComponents = map['blend_components'];

    return DoseDetails(
      form: DoseFormDetails.fromStorageValue(map['form'] as String?),
      strengthAmount: (map['strength_amount'] as num?)?.toDouble(),
      strengthUnit: map['strength_unit'] == null
          ? null
          : DoseUnitDetails.fromStorageValue(map['strength_unit'] as String?),
      scheduledQuantity: (map['scheduled_quantity'] as num?)?.toDouble(),
      vialAmount: (map['vial_amount'] as num?)?.toDouble(),
      vialUnit: map['vial_unit'] == null
          ? null
          : DoseUnitDetails.fromStorageValue(map['vial_unit'] as String?),
      reconstitutionVolumeMl: (map['reconstitution_volume_ml'] as num?)
          ?.toDouble(),
      syringeType: map['syringe_type'] as String? ?? 'U-100',
      showDrawUnitsOnCards: map['show_draw_units_on_cards'] as bool? ?? false,
      blendComponents: rawComponents is List
          ? rawComponents
                .whereType<Map>()
                .map(
                  (item) => BlendComponent.fromMap(
                    item.map((key, value) => MapEntry(key.toString(), value)),
                  ),
                )
                .toList()
          : const [],
    );
  }

  String toJson() => jsonEncode(toMap());

  static DoseDetails? fromJson(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return null;

      return DoseDetails.fromMap(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } catch (_) {
      return null;
    }
  }

  static double? _convertAmount(
    double amount, {
    required DoseUnit from,
    required DoseUnit to,
  }) {
    if (from == to) return amount;

    final milligrams = switch (from) {
      DoseUnit.g => amount * 1000,
      DoseUnit.mg => amount,
      DoseUnit.mcg => amount / 1000,
      _ => null,
    };

    if (milligrams == null) return null;

    return switch (to) {
      DoseUnit.g => milligrams / 1000,
      DoseUnit.mg => milligrams,
      DoseUnit.mcg => milligrams * 1000,
      _ => null,
    };
  }
}
