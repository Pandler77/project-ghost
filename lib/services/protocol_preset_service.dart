import '../models/protocol_category.dart';
import '../models/protocol_preset.dart';

class ProtocolPresetService {
  static const List<ProtocolPreset> _presets = [
    // Peptides
    ProtocolPreset(
      name: 'Retatrutide',
      category: ProtocolCategory.peptide,
      defaultUnit: 'mg',
    ),
    ProtocolPreset(
      name: 'Tirzepatide',
      category: ProtocolCategory.peptide,
      defaultUnit: 'mg',
    ),
    ProtocolPreset(
      name: 'Semaglutide',
      category: ProtocolCategory.peptide,
      defaultUnit: 'mg',
    ),
    ProtocolPreset(
      name: 'Cagrilintide',
      category: ProtocolCategory.peptide,
      defaultUnit: 'mg',
    ),
    ProtocolPreset(
      name: 'GHK-Cu',
      category: ProtocolCategory.peptide,
      defaultUnit: 'mg',
    ),
    ProtocolPreset(
      name: 'BPC-157',
      category: ProtocolCategory.peptide,
      defaultUnit: 'mcg',
    ),
    ProtocolPreset(
      name: 'TB-500',
      category: ProtocolCategory.peptide,
      defaultUnit: 'mg',
    ),
    ProtocolPreset(
      name: 'Tesamorelin',
      category: ProtocolCategory.peptide,
      defaultUnit: 'mg',
    ),
    ProtocolPreset(
      name: 'CJC-1295',
      category: ProtocolCategory.peptide,
      defaultUnit: 'mcg',
    ),
    ProtocolPreset(
      name: 'Ipamorelin',
      category: ProtocolCategory.peptide,
      defaultUnit: 'mcg',
    ),
    ProtocolPreset(
      name: 'NAD+',
      category: ProtocolCategory.peptide,
      defaultUnit: 'mg',
    ),
    ProtocolPreset(
      name: 'Glutathione',
      category: ProtocolCategory.peptide,
      defaultUnit: 'mg',
    ),
    ProtocolPreset(
      name: 'KPV',
      category: ProtocolCategory.peptide,
      defaultUnit: 'mg',
    ),
    ProtocolPreset(
      name: 'MOTS-c',
      category: ProtocolCategory.peptide,
      defaultUnit: 'mg',
    ),
    ProtocolPreset(
      name: 'Selank',
      category: ProtocolCategory.peptide,
      defaultUnit: 'mcg',
    ),
    ProtocolPreset(
      name: 'Semax',
      category: ProtocolCategory.peptide,
      defaultUnit: 'mcg',
    ),

    // Prescriptions
    ProtocolPreset(
      name: 'Metformin',
      category: ProtocolCategory.prescription,
      defaultUnit: 'mg',
    ),
    ProtocolPreset(
      name: 'Lisinopril',
      category: ProtocolCategory.prescription,
      defaultUnit: 'mg',
    ),
    ProtocolPreset(
      name: 'Atorvastatin',
      category: ProtocolCategory.prescription,
      defaultUnit: 'mg',
    ),
    ProtocolPreset(
      name: 'Levothyroxine',
      category: ProtocolCategory.prescription,
      defaultUnit: 'mcg',
    ),
    ProtocolPreset(
      name: 'Omeprazole',
      category: ProtocolCategory.prescription,
      defaultUnit: 'mg',
    ),

    // Supplements
    ProtocolPreset(
      name: 'Fish Oil',
      category: ProtocolCategory.supplement,
      defaultUnit: 'capsule',
    ),
    ProtocolPreset(
      name: 'Creatine',
      category: ProtocolCategory.supplement,
      defaultUnit: 'g',
    ),
    ProtocolPreset(
      name: 'Magnesium Glycinate',
      category: ProtocolCategory.supplement,
      defaultUnit: 'mg',
    ),
    ProtocolPreset(
      name: 'Berberine',
      category: ProtocolCategory.supplement,
      defaultUnit: 'mg',
    ),
    ProtocolPreset(
      name: 'NAC',
      category: ProtocolCategory.supplement,
      defaultUnit: 'mg',
    ),
    ProtocolPreset(
      name: 'CoQ10',
      category: ProtocolCategory.supplement,
      defaultUnit: 'mg',
    ),
    ProtocolPreset(
      name: 'Ashwagandha',
      category: ProtocolCategory.supplement,
      defaultUnit: 'mg',
    ),
    ProtocolPreset(
      name: 'Electrolytes',
      category: ProtocolCategory.supplement,
      defaultUnit: 'serving',
    ),

    // Vitamins
    ProtocolPreset(
      name: 'Vitamin D3',
      category: ProtocolCategory.vitamin,
      defaultUnit: 'IU',
    ),
    ProtocolPreset(
      name: 'Vitamin K2',
      category: ProtocolCategory.vitamin,
      defaultUnit: 'mcg',
    ),
    ProtocolPreset(
      name: 'Vitamin B12',
      category: ProtocolCategory.vitamin,
      defaultUnit: 'mcg',
    ),
    ProtocolPreset(
      name: 'Vitamin C',
      category: ProtocolCategory.vitamin,
      defaultUnit: 'mg',
    ),
    ProtocolPreset(
      name: 'Vitamin B Complex',
      category: ProtocolCategory.vitamin,
      defaultUnit: 'capsule',
    ),
    ProtocolPreset(
      name: 'Zinc',
      category: ProtocolCategory.vitamin,
      defaultUnit: 'mg',
    ),
    ProtocolPreset(
      name: 'Iron',
      category: ProtocolCategory.vitamin,
      defaultUnit: 'mg',
    ),
    ProtocolPreset(
      name: 'Multivitamin',
      category: ProtocolCategory.vitamin,
      defaultUnit: 'tablet',
    ),
  ];

  List<ProtocolPreset> getByCategory(ProtocolCategory category) {
    final presets = _presets
        .where((preset) => preset.category == category)
        .toList();

    presets.sort(
      (first, second) =>
          first.name.toLowerCase().compareTo(second.name.toLowerCase()),
    );

    return presets;
  }

  List<ProtocolPreset> search({
    required ProtocolCategory category,
    required String query,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final categoryPresets = getByCategory(category);

    if (normalizedQuery.isEmpty) {
      return categoryPresets;
    }

    return categoryPresets.where((preset) {
      return preset.name.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  ProtocolPreset? findByName({
    required ProtocolCategory category,
    required String name,
  }) {
    final normalizedName = name.trim().toLowerCase();

    for (final preset in getByCategory(category)) {
      if (preset.name.toLowerCase() == normalizedName) {
        return preset;
      }
    }

    return null;
  }
}
