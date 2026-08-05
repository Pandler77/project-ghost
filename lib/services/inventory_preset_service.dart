import '../models/inventory_preset.dart';
import '../models/protocol.dart';

class InventoryPresetService {
  InventoryPresetService._();

  static final InventoryPresetService instance = InventoryPresetService._();

  static const List<InventoryPreset> _presets = [
    InventoryPreset(
      name: 'Retatrutide',
      aliases: ['Reta', 'LY3437943'],
      containerType: 'Vial',
      defaultSize: 10,
      defaultUnit: 'mg',
      defaultShippingDays: 14,
      defaultLowStockThreshold: 1,
      category: 'Peptide',
      iconName: 'science',
      supportsReconstitution: true,
    ),

    InventoryPreset(
      name: 'Tirzepatide',
      aliases: ['Tirz', 'Mounjaro', 'Zepbound'],
      containerType: 'Vial',
      defaultSize: 10,
      defaultUnit: 'mg',
      defaultShippingDays: 14,
      defaultLowStockThreshold: 1,
      category: 'Peptide',
      iconName: 'science',
      supportsReconstitution: true,
    ),

    InventoryPreset(
      name: 'Semaglutide',
      aliases: ['Sema', 'Ozempic', 'Wegovy'],
      containerType: 'Vial',
      defaultSize: 5,
      defaultUnit: 'mg',
      defaultShippingDays: 14,
      defaultLowStockThreshold: 1,
      category: 'Peptide',
      iconName: 'science',
      supportsReconstitution: true,
    ),

    InventoryPreset(
      name: 'GHK-Cu',
      aliases: ['GHK', 'Copper Peptide'],
      containerType: 'Vial',
      defaultSize: 50,
      defaultUnit: 'mg',
      defaultShippingDays: 14,
      defaultLowStockThreshold: 1,
      category: 'Peptide',
      iconName: 'science',
      supportsReconstitution: true,
    ),

    InventoryPreset(
      name: 'Glutathione',
      aliases: ['Gluta', 'GSH'],
      containerType: 'Vial',
      defaultSize: 600,
      defaultUnit: 'mg',
      defaultShippingDays: 14,
      defaultLowStockThreshold: 1,
      category: 'Peptide',
      iconName: 'science',
      supportsReconstitution: true,
    ),

    InventoryPreset(
      name: 'NAD+',
      aliases: ['NAD'],
      containerType: 'Vial',
      defaultSize: 500,
      defaultUnit: 'mg',
      defaultShippingDays: 14,
      defaultLowStockThreshold: 1,
      category: 'Peptide',
      iconName: 'science',
      supportsReconstitution: true,
    ),

    InventoryPreset(
      name: 'Tesamorelin',
      aliases: ['Tesa'],
      containerType: 'Vial',
      defaultSize: 10,
      defaultUnit: 'mg',
      defaultShippingDays: 14,
      defaultLowStockThreshold: 1,
      category: 'Peptide',
      iconName: 'science',
      supportsReconstitution: true,
    ),
  ];

  List<InventoryPreset> get presets => List.unmodifiable(_presets);

  InventoryPreset? findByName(String name) {
    final search = name.trim().toLowerCase();

    for (final preset in _presets) {
      if (preset.name.toLowerCase() == search) {
        return preset;
      }

      for (final alias in preset.aliases) {
        if (alias.toLowerCase() == search) {
          return preset;
        }
      }
    }

    return null;
  }

  InventoryPreset? findByProtocol(Protocol protocol) {
    return findByName(protocol.name);
  }

  List<InventoryPreset> search(String query) {
    if (query.trim().isEmpty) {
      return presets;
    }

    final search = query.toLowerCase();

    return _presets.where((preset) {
      if (preset.name.toLowerCase().contains(search)) {
        return true;
      }

      return preset.aliases.any(
        (alias) => alias.toLowerCase().contains(search),
      );
    }).toList();
  }

  List<String> get categories {
    final values = _presets.map((preset) => preset.category).toSet().toList();

    values.sort();

    return values;
  }

  List<InventoryPreset> presetsForCategory(String category) {
    return _presets.where((preset) {
      return preset.category == category;
    }).toList();
  }
}
