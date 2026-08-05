enum DoseUnit { mg, mcg, g, mL, units, iu, tablets, capsules, sprays, drops }

extension DoseUnitDetails on DoseUnit {
  String get label {
    return switch (this) {
      DoseUnit.mg => 'mg',
      DoseUnit.mcg => 'mcg',
      DoseUnit.g => 'g',
      DoseUnit.mL => 'mL',
      DoseUnit.units => 'units',
      DoseUnit.iu => 'IU',
      DoseUnit.tablets => 'tablets',
      DoseUnit.capsules => 'capsules',
      DoseUnit.sprays => 'sprays',
      DoseUnit.drops => 'drops',
    };
  }

  String get storageValue => name;

  static DoseUnit fromStorageValue(
    String? value, {
    DoseUnit fallback = DoseUnit.mg,
  }) {
    if (value == null || value.trim().isEmpty) {
      return fallback;
    }

    final normalized = value.trim().toLowerCase();

    return switch (normalized) {
      'mg' => DoseUnit.mg,
      'mcg' || 'µg' || 'ug' => DoseUnit.mcg,
      'g' => DoseUnit.g,
      'ml' => DoseUnit.mL,
      'unit' || 'units' || 'u' => DoseUnit.units,
      'iu' || 'i.u.' => DoseUnit.iu,
      'tablet' || 'tablets' || 'tab' || 'tabs' => DoseUnit.tablets,
      'capsule' || 'capsules' || 'cap' || 'caps' => DoseUnit.capsules,
      'spray' || 'sprays' => DoseUnit.sprays,
      'drop' || 'drops' => DoseUnit.drops,
      _ => fallback,
    };
  }
}
