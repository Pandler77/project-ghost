import 'dart:math';

import '../models/injection_site.dart';
import '../models/rotation_mode.dart';

class InjectionRotationResult {
  const InjectionRotationResult({
    required this.nextSite,
    required this.previousSite,
    required this.mode,
    required this.enabledSiteCount,
  });

  final InjectionSite nextSite;
  final InjectionSite? previousSite;
  final RotationMode mode;
  final int enabledSiteCount;
}

class InjectionRotationService {
  InjectionRotationService({Random? random}) : _random = random ?? Random();

  final Random _random;

  InjectionRotationResult getNextSite({
    required RotationMode mode,
    required Set<InjectionSite> enabledSites,
    required List<InjectionSite> history,
  }) {
    final orderedSites = _orderedEnabledSites(enabledSites);

    if (orderedSites.isEmpty) {
      throw StateError('At least one injection site must be enabled.');
    }

    final previousSite = _findMostRecentEnabledSite(history, enabledSites);

    final nextSite = switch (mode) {
      RotationMode.sequential => _getSequentialSite(
        orderedSites: orderedSites,
        previousSite: previousSite,
      ),
      RotationMode.random => _getRandomSite(
        orderedSites: orderedSites,
        previousSite: previousSite,
      ),
    };

    return InjectionRotationResult(
      nextSite: nextSite,
      previousSite: previousSite,
      mode: mode,
      enabledSiteCount: orderedSites.length,
    );
  }

  InjectionSite _getSequentialSite({
    required List<InjectionSite> orderedSites,
    required InjectionSite? previousSite,
  }) {
    if (previousSite == null) {
      return orderedSites.first;
    }

    final previousIndex = orderedSites.indexOf(previousSite);

    if (previousIndex == -1) {
      return orderedSites.first;
    }

    final nextIndex = (previousIndex + 1) % orderedSites.length;

    return orderedSites[nextIndex];
  }

  InjectionSite _getRandomSite({
    required List<InjectionSite> orderedSites,
    required InjectionSite? previousSite,
  }) {
    if (orderedSites.length == 1) {
      return orderedSites.first;
    }

    final candidates = orderedSites
        .where((site) => site != previousSite)
        .toList();

    return candidates[_random.nextInt(candidates.length)];
  }

  InjectionSite? _findMostRecentEnabledSite(
    List<InjectionSite> history,
    Set<InjectionSite> enabledSites,
  ) {
    for (final site in history.reversed) {
      if (enabledSites.contains(site)) {
        return site;
      }
    }

    return null;
  }

  List<InjectionSite> _orderedEnabledSites(Set<InjectionSite> enabledSites) {
    const orderedSites = [
      InjectionSite.abdomenTopLeft,
      InjectionSite.abdomenTopRight,
      InjectionSite.abdomenBottomRight,
      InjectionSite.abdomenBottomLeft,
      InjectionSite.loveHandleLeft,
      InjectionSite.loveHandleRight,
      InjectionSite.armLeft,
      InjectionSite.armRight,
      InjectionSite.thighLeft,
      InjectionSite.thighRight,
      InjectionSite.gluteLeft,
      InjectionSite.gluteRight,
      InjectionSite.custom,
    ];

    return orderedSites.where(enabledSites.contains).toList(growable: false);
  }
}
