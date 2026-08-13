enum RotationMode { sequential, random }

extension RotationModeDetails on RotationMode {
  String get label {
    return switch (this) {
      RotationMode.sequential => 'Sequential',
      RotationMode.random => 'Random',
    };
  }

  String get storageValue {
    return switch (this) {
      RotationMode.sequential => 'sequential',
      RotationMode.random => 'random',
    };
  }

  static RotationMode fromStorageValue(String? value) {
    return switch (value) {
      'random' => RotationMode.random,
      _ => RotationMode.sequential,
    };
  }
}
