import 'home_section.dart';

class HomeLayout {
  const HomeLayout({required this.visibleSections});

  final List<HomeSection> visibleSections;

  static const HomeLayout defaultLayout = HomeLayout(
    visibleSections: [
      HomeSection.today,
      HomeSection.ghostSupply,
      HomeSection.upcoming,
      HomeSection.weight,
    ],
  );

  bool isVisible(HomeSection section) {
    return visibleSections.contains(section);
  }

  HomeLayout copyWith({List<HomeSection>? visibleSections}) {
    return HomeLayout(visibleSections: visibleSections ?? this.visibleSections);
  }
}
