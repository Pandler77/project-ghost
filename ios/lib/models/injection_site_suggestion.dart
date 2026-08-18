import 'injection_site.dart';

class InjectionSiteSuggestion {
  const InjectionSiteSuggestion({
    required this.recommendedSite,
    required this.previousSite,
  });

  final InjectionSite? recommendedSite;
  final InjectionSite? previousSite;
}
