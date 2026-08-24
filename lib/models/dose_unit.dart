enum DoseUnit {
  mg,
  mcg,
  g,
  mL,
  units,
  iu,

  tablets,
  capsules,
  pills,

  sprays,
  drops,
  patches,

  servings,
}

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
      DoseUnit.pills => 'pills',

      DoseUnit.sprays => 'sprays',
      DoseUnit.drops => 'drops',
      DoseUnit.patches => 'patches',

      DoseUnit.servings => 'servings',
    };
  }

  String get singularLabel {
    return switch (this) {
      DoseUnit.mg => 'mg',
      DoseUnit.mcg => 'mcg',
      DoseUnit.g => 'g',
      DoseUnit.mL => 'mL',
      DoseUnit.units => 'unit',
      DoseUnit.iu => 'IU',

      DoseUnit.tablets => 'tablet',
      DoseUnit.capsules => 'capsule',
      DoseUnit.pills => 'pill',

      DoseUnit.sprays => 'spray',
      DoseUnit.drops => 'drop',
      DoseUnit.patches => 'patch',

      DoseUnit.servings => 'serving',
    };
  }

  String labelForAmount(double amount) {
    if (amount == 1) {
      return singularLabel;
    }

    return label;
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

      'g' || 'gram' || 'grams' => DoseUnit.g,

      'ml' => DoseUnit.mL,

      'unit' || 'units' || 'u' => DoseUnit.units,

      'iu' || 'i.u.' || 'i.u' => DoseUnit.iu,

      'tablet' || 'tablets' || 'tab' || 'tabs' => DoseUnit.tablets,

      'capsule' || 'capsules' || 'cap' || 'caps' => DoseUnit.capsules,

      'pill' || 'pills' => DoseUnit.pills,

      'spray' || 'sprays' => DoseUnit.sprays,

      'drop' || 'drops' => DoseUnit.drops,

      'patch' || 'patches' => DoseUnit.patches,

      'serving' || 'servings' => DoseUnit.servings,

      _ => fallback,
    };
  }
}
