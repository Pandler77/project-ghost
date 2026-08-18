enum ProtocolCategory {
  peptide,
  hormonesAndTrt,
  medication,
  supplementsAndVitamins,
  otherWellness,

  /// Retained so protocols created by older Ghost builds still deserialize.
  /// New presets should use one of the active categories above.
  researchCompound,

  custom,
}

extension ProtocolCategoryDetails on ProtocolCategory {
  String get label {
    return switch (this) {
      ProtocolCategory.peptide => 'Peptides & Research',
      ProtocolCategory.hormonesAndTrt => 'Hormones & TRT',
      ProtocolCategory.medication => 'Medication',
      ProtocolCategory.supplementsAndVitamins => 'Supplements & Vitamins',
      ProtocolCategory.otherWellness => 'Other & Wellness',
      ProtocolCategory.researchCompound => 'Research Compound',
      ProtocolCategory.custom => 'Custom',
    };
  }

  String get storageValue {
    return switch (this) {
      ProtocolCategory.peptide => 'peptide',
      ProtocolCategory.hormonesAndTrt => 'hormones_and_trt',
      ProtocolCategory.medication => 'medication',
      ProtocolCategory.supplementsAndVitamins =>
        'supplements_and_vitamins',
      ProtocolCategory.otherWellness => 'other_wellness',
      ProtocolCategory.researchCompound => 'research_compound',
      ProtocolCategory.custom => 'custom',
    };
  }

  bool get showInAddProtocol {
    return switch (this) {
      ProtocolCategory.researchCompound => false,
      _ => true,
    };
  }

  static ProtocolCategory fromStorageValue(String? value) {
    return switch (value) {
      'peptide' => ProtocolCategory.peptide,
      'hormones_and_trt' => ProtocolCategory.hormonesAndTrt,
      'medication' => ProtocolCategory.medication,
      'supplements_and_vitamins' =>
        ProtocolCategory.supplementsAndVitamins,
      'other_wellness' => ProtocolCategory.otherWellness,
      'research_compound' => ProtocolCategory.researchCompound,
      'custom' => ProtocolCategory.custom,

      // Legacy mappings.
      'prescription' => ProtocolCategory.medication,
      'supplement' => ProtocolCategory.supplementsAndVitamins,
      'vitamin' => ProtocolCategory.supplementsAndVitamins,

      _ => ProtocolCategory.custom,
    };
  }
}
