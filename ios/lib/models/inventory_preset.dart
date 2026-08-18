class InventoryPreset {
  const InventoryPreset({
    required this.name,
    required this.aliases,
    required this.containerType,
    required this.defaultSize,
    required this.defaultUnit,
    required this.defaultShippingDays,
    required this.defaultLowStockThreshold,
    required this.category,
    required this.iconName,
    required this.supportsReconstitution,
    this.isBuiltIn = true,
  });

  /// Display name.
  final String name;

  /// Search aliases.
  final List<String> aliases;

  /// Vial, Bottle, Box, Pen...
  final String containerType;

  /// Amount that fits in one container.
  final double defaultSize;

  /// mg, mL, capsules, tablets...
  final String defaultUnit;

  /// Average shipping estimate.
  final int defaultShippingDays;

  /// Alert user when this many unopened remain.
  final int defaultLowStockThreshold;

  /// Peptide, Medication, Supplement, Vitamin...
  final String category;

  /// Stored as text to keep this model Flutter-independent.
  final String iconName;

  /// Enables Ghost Calculator integration later.
  final bool supportsReconstitution;

  /// Built into Ghost or created by the user.
  final bool isBuiltIn;
}
