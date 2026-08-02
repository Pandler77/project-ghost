import 'protocol_category.dart';

class ProtocolPreset {
  const ProtocolPreset({
    required this.name,
    required this.category,
    this.defaultUnit,
  });

  final String name;
  final ProtocolCategory category;
  final String? defaultUnit;
}
