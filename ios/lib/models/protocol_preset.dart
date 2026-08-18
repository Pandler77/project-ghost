import 'protocol_category.dart';
import 'protocol_type.dart';

class ProtocolPreset {
  const ProtocolPreset({
    required this.name,
    required this.category,
    this.aliases = const [],
    this.defaultUnit,
    this.defaultProtocolType,
    this.defaultContainerType,
    this.defaultInventoryUnit,
  });

  final String name;
  final ProtocolCategory category;

  /// Alternate search terms such as "Reta", "Test C", or "BPC157".
  final List<String> aliases;

  /// Suggested dose unit during protocol creation.
  final String? defaultUnit;

  /// Suggested administration route during protocol creation.
  final ProtocolType? defaultProtocolType;

  /// Suggested Ghost Supply container type.
  final String? defaultContainerType;

  /// Suggested Ghost Supply inventory unit.
  final String? defaultInventoryUnit;

  bool matchesQuery(String query) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return true;
    }

    if (name.toLowerCase().contains(normalizedQuery)) {
      return true;
    }

    return aliases.any(
      (alias) => alias.toLowerCase().contains(normalizedQuery),
    );
  }

  bool matchesExactNameOrAlias(String value) {
    final normalizedValue = value.trim().toLowerCase();

    if (normalizedValue.isEmpty) {
      return false;
    }

    if (name.toLowerCase() == normalizedValue) {
      return true;
    }

    return aliases.any(
      (alias) => alias.toLowerCase() == normalizedValue,
    );
  }
}
