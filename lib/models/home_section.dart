enum HomeSection { today, weight, upcoming, recentActivity }

extension HomeSectionDetails on HomeSection {
  String get storageValue => name;

  String get title {
    return switch (this) {
      HomeSection.today => 'Today',
      HomeSection.weight => 'Weight',
      HomeSection.upcoming => 'Upcoming',
      HomeSection.recentActivity => 'Recent Activity',
    };
  }

  String get description {
    return switch (this) {
      HomeSection.today => 'Protocols and tasks due today.',
      HomeSection.weight => 'Current weight and progress.',
      HomeSection.upcoming => 'Your next scheduled actions.',
      HomeSection.recentActivity => 'Recent doses and weight entries.',
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
