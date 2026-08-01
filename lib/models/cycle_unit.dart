enum CycleUnit { days, weeks, months }

extension CycleUnitDetails on CycleUnit {
  String get label {
    return switch (this) {
      CycleUnit.days => 'Days',
      CycleUnit.weeks => 'Weeks',
      CycleUnit.months => 'Months',
    };
  }

  String get singularLabel {
    return switch (this) {
      CycleUnit.days => 'Day',
      CycleUnit.weeks => 'Week',
      CycleUnit.months => 'Month',
    };
  }

  String get storageValue => name;

  static CycleUnit fromStorageValue(
    String? value, {
    CycleUnit fallback = CycleUnit.weeks,
  }) {
    for (final unit in CycleUnit.values) {
      if (unit.storageValue == value) {
        return unit;
      }
    }

    return fallback;
  }
}
