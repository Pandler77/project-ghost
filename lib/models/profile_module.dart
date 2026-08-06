enum ProfileModule { protocols, weight, inventory, notes, photos }

extension ProfileModuleDetails on ProfileModule {
  String get label {
    return switch (this) {
      ProfileModule.protocols => 'Protocols',
      ProfileModule.weight => 'Weight',
      ProfileModule.inventory => 'Inventory',
      ProfileModule.notes => 'Notes & Symptoms',
      ProfileModule.photos => 'Progress Photos',
    };
  }

  String get description {
    return switch (this) {
      ProfileModule.protocols =>
        'Track medications, injections, schedules, and reminders.',
      ProfileModule.weight => 'Log weight and monitor progress over time.',
      ProfileModule.inventory =>
        'Track supplies, remaining amounts, and reorder timing.',
      ProfileModule.notes =>
        'Record symptoms, side effects, and general notes.',
      ProfileModule.photos => 'Save progress photos for visual tracking.',
    };
  }

  String get storageValue {
    return switch (this) {
      ProfileModule.protocols => 'protocols',
      ProfileModule.weight => 'weight',
      ProfileModule.inventory => 'inventory',
      ProfileModule.notes => 'notes',
      ProfileModule.photos => 'photos',
    };
  }

  static ProfileModule? fromStorageValue(String value) {
    return switch (value) {
      'protocols' => ProfileModule.protocols,
      'weight' => ProfileModule.weight,
      'inventory' => ProfileModule.inventory,
      'notes' => ProfileModule.notes,
      'photos' => ProfileModule.photos,
      _ => null,
    };
  }

  static Set<ProfileModule> decode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return defaultModules;
    }

    final modules = value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .map(fromStorageValue)
        .whereType<ProfileModule>()
        .toSet();

    return modules.isEmpty ? defaultModules : modules;
  }

  static String encode(Iterable<ProfileModule> modules) {
    return modules.map((module) => module.storageValue).join(',');
  }

  static Set<ProfileModule> get defaultModules => {
    ProfileModule.protocols,
    ProfileModule.weight,
    ProfileModule.inventory,
  };
}
