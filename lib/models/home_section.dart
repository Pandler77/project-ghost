enum HomeSection {
  today,
  ghostSupply,
  weight,
  progressPhotos,
  upcoming,
  recentActivity,
  notesSymptoms,
}

extension HomeSectionDetails on HomeSection {
  String get storageValue => name;

  String get title {
    return switch (this) {
      HomeSection.today => 'Today',
      HomeSection.ghostSupply => 'MODOSE Supply',
      HomeSection.weight => 'Weight',
      HomeSection.progressPhotos => 'Progress Photos',
      HomeSection.upcoming => 'Upcoming',
      HomeSection.recentActivity => 'Recent Activity',
      HomeSection.notesSymptoms => 'Notes & Symptoms',
    };
  }

  String get description {
    return switch (this) {
      HomeSection.today => 'Protocols and tasks due today.',
      HomeSection.ghostSupply => 'Current supply levels and low-stock status.',
      HomeSection.weight => 'Current weight and progress.',
      HomeSection.progressPhotos => 'Progress photo schedule and next session.',
      HomeSection.upcoming => 'Your next scheduled actions.',
      HomeSection.recentActivity => 'Recent doses and weight entries.',
      HomeSection.notesSymptoms => 'Quick access to symptoms and recent notes.',
    };
  }

  static HomeSection? fromStorageValue(String value) {
    for (final section in HomeSection.values) {
      if (section.storageValue == value) {
        return section;
      }
    }

    return null;
  }
}

