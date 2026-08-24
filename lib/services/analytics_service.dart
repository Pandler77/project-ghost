import '../models/dose_record.dart';
import '../models/protocol.dart';
import '../models/weight_record.dart';

class AnalyticsSummary {
  const AnalyticsSummary({
    required this.weight,
    required this.adherence,
    required this.activity,
  });

  final WeightAnalytics weight;
  final AdherenceAnalytics adherence;
  final ActivityAnalytics activity;
}

class WeightAnalytics {
  const WeightAnalytics({
    required this.entryCount,
    required this.startingWeight,
    required this.currentWeight,
    required this.highestWeight,
    required this.lowestWeight,
    required this.totalChange,
    required this.percentChange,
    required this.averageWeeklyChange,
    required this.change7Days,
    required this.change30Days,
    required this.daysTracked,
  });

  final int entryCount;

  final double? startingWeight;
  final double? currentWeight;
  final double? highestWeight;
  final double? lowestWeight;

  final double? totalChange;
  final double? percentChange;

  final double? averageWeeklyChange;
  final double? change7Days;
  final double? change30Days;

  final int daysTracked;

  bool get hasData => entryCount > 0;
}

class AdherenceAnalytics {
  const AdherenceAnalytics({
    required this.totalRecords,
    required this.takenDoses,
    required this.skippedDoses,
    required this.missedDoses,
    required this.adherencePercent,
    required this.currentStreak,
    required this.longestStreak,
    required this.byProtocol,
  });

  final int totalRecords;

  final int takenDoses;
  final int skippedDoses;
  final int missedDoses;

  final double adherencePercent;

  final int currentStreak;
  final int longestStreak;

  final List<ProtocolAdherenceAnalytics> byProtocol;

  bool get hasData => totalRecords > 0;
}

class ProtocolAdherenceAnalytics {
  const ProtocolAdherenceAnalytics({
    required this.protocolId,
    required this.protocolName,
    required this.protocolColorValue,
    required this.totalRecords,
    required this.takenDoses,
    required this.skippedDoses,
    required this.missedDoses,
    required this.adherencePercent,
    required this.currentStreak,
    required this.longestStreak,
  });

  final String protocolId;
  final String protocolName;
  final int protocolColorValue;

  final int totalRecords;
  final int takenDoses;
  final int skippedDoses;
  final int missedDoses;

  final double adherencePercent;

  final int currentStreak;
  final int longestStreak;
}

class ActivityAnalytics {
  const ActivityAnalytics({
    required this.dosesThisWeek,
    required this.dosesThisMonth,
    required this.weightEntriesThisWeek,
    required this.weightEntriesThisMonth,
  });

  final int dosesThisWeek;
  final int dosesThisMonth;

  final int weightEntriesThisWeek;
  final int weightEntriesThisMonth;
}

class AnalyticsService {
  const AnalyticsService();

  AnalyticsSummary calculate({
    required List<DoseRecord> doseRecords,
    required List<Protocol> protocols,
    required List<WeightRecord> weightRecords,
    DateTime? startDate,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    final filteredDoseRecords = startDate == null
        ? doseRecords
        : doseRecords.where((record) {
            return !record.scheduledFor.isBefore(startDate);
          }).toList();

    final filteredWeightRecords = startDate == null
        ? weightRecords
        : weightRecords.where((record) {
            return !record.recordedAt.isBefore(startDate);
          }).toList();

    return AnalyticsSummary(
      weight: calculateWeight(filteredWeightRecords),
      adherence: calculateAdherence(
        filteredDoseRecords,
        protocols: protocols,
        now: currentTime,
      ),
      activity: calculateActivity(
        doseRecords: filteredDoseRecords,
        weightRecords: filteredWeightRecords,
        now: currentTime,
      ),
    );
  }

  WeightAnalytics calculateWeight(List<WeightRecord> records) {
    if (records.isEmpty) {
      return const WeightAnalytics(
        entryCount: 0,
        startingWeight: null,
        currentWeight: null,
        highestWeight: null,
        lowestWeight: null,
        totalChange: null,
        percentChange: null,
        averageWeeklyChange: null,
        change7Days: null,
        change30Days: null,
        daysTracked: 0,
      );
    }

    final sorted = List<WeightRecord>.from(records)
      ..sort((first, second) => first.recordedAt.compareTo(second.recordedAt));

    final first = sorted.first;
    final latest = sorted.last;

    var highest = first.weight;
    var lowest = first.weight;

    for (final record in sorted) {
      if (record.weight > highest) {
        highest = record.weight;
      }

      if (record.weight < lowest) {
        lowest = record.weight;
      }
    }

    final totalChange = latest.weight - first.weight;

    final percentChange = first.weight <= 0
        ? null
        : (totalChange / first.weight) * 100;

    final minutesTracked = latest.recordedAt
        .difference(first.recordedAt)
        .inMinutes
        .abs();

    final daysTracked = minutesTracked ~/ Duration.minutesPerDay;

    double? averageWeeklyChange;

    if (daysTracked >= 7) {
      final weeks = minutesTracked / Duration.minutesPerDay / 7;

      if (weeks > 0) {
        averageWeeklyChange = totalChange / weeks;
      }
    }

    return WeightAnalytics(
      entryCount: sorted.length,
      startingWeight: first.weight,
      currentWeight: latest.weight,
      highestWeight: highest,
      lowestWeight: lowest,
      totalChange: totalChange,
      percentChange: percentChange,
      averageWeeklyChange: averageWeeklyChange,
      change7Days: _weightChangeOverPeriod(
        sorted,
        latest.recordedAt,
        const Duration(days: 7),
      ),
      change30Days: _weightChangeOverPeriod(
        sorted,
        latest.recordedAt,
        const Duration(days: 30),
      ),
      daysTracked: daysTracked,
    );
  }

  AdherenceAnalytics calculateAdherence(
    List<DoseRecord> records, {
    required List<Protocol> protocols,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    final eligibleRecords =
        records.where((record) {
          final wasResolvedEarly =
              record.completedAt != null &&
              !record.completedAt!.isAfter(currentTime);

          final scheduleHasPassed = !record.scheduledFor.isAfter(currentTime);

          return wasResolvedEarly || scheduleHasPassed;
        }).toList()
          ..sort(
            (first, second) =>
                first.scheduledFor.compareTo(second.scheduledFor),
          );

    if (eligibleRecords.isEmpty) {
      return const AdherenceAnalytics(
        totalRecords: 0,
        takenDoses: 0,
        skippedDoses: 0,
        missedDoses: 0,
        adherencePercent: 0,
        currentStreak: 0,
        longestStreak: 0,
        byProtocol: [],
      );
    }

    final taken = eligibleRecords
        .where((record) => record.status == DoseRecordStatus.taken)
        .length;

    final skipped = eligibleRecords
        .where((record) => record.status == DoseRecordStatus.skipped)
        .length;

    final missed = eligibleRecords
        .where((record) => record.status == DoseRecordStatus.missed)
        .length;

    final adherence = taken / eligibleRecords.length * 100;

    final streaks = _calculateStreaks(eligibleRecords);

    final protocolsById = <String, Protocol>{
      for (final protocol in protocols) protocol.id: protocol,
    };

    final grouped = <String, List<DoseRecord>>{};

    for (final record in eligibleRecords) {
      grouped.putIfAbsent(record.protocolId, () => <DoseRecord>[]);
      grouped[record.protocolId]!.add(record);
    }

    final protocolAnalytics = <ProtocolAdherenceAnalytics>[];

    for (final entry in grouped.entries) {
      final protocolRecords = entry.value;

      if (protocolRecords.isEmpty) {
        continue;
      }

      protocolRecords.sort(
        (first, second) => first.scheduledFor.compareTo(second.scheduledFor),
      );

      final protocol = protocolsById[entry.key];

      final takenForProtocol = protocolRecords
          .where((record) => record.status == DoseRecordStatus.taken)
          .length;

      final skippedForProtocol = protocolRecords
          .where((record) => record.status == DoseRecordStatus.skipped)
          .length;

      final missedForProtocol = protocolRecords
          .where((record) => record.status == DoseRecordStatus.missed)
          .length;

      final protocolStreaks = _calculateStreaks(protocolRecords);

      protocolAnalytics.add(
        ProtocolAdherenceAnalytics(
          protocolId: entry.key,
          protocolName: protocol?.name ?? 'Deleted Protocol',
          protocolColorValue: protocol?.colorValue ?? 0,
          totalRecords: protocolRecords.length,
          takenDoses: takenForProtocol,
          skippedDoses: skippedForProtocol,
          missedDoses: missedForProtocol,
          adherencePercent: takenForProtocol / protocolRecords.length * 100,
          currentStreak: protocolStreaks.current,
          longestStreak: protocolStreaks.longest,
        ),
      );
    }

    protocolAnalytics.sort(
      (first, second) =>
          second.adherencePercent.compareTo(first.adherencePercent),
    );

    return AdherenceAnalytics(
      totalRecords: eligibleRecords.length,
      takenDoses: taken,
      skippedDoses: skipped,
      missedDoses: missed,
      adherencePercent: adherence,
      currentStreak: streaks.current,
      longestStreak: streaks.longest,
      byProtocol: protocolAnalytics,
    );
  }

  ActivityAnalytics calculateActivity({
    required List<DoseRecord> doseRecords,
    required List<WeightRecord> weightRecords,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    final startOfWeek = _startOfWeek(currentTime);
    final startOfMonth = DateTime(currentTime.year, currentTime.month, 1);

    final completedRecords = doseRecords.where(
      (record) =>
          record.status == DoseRecordStatus.taken && record.completedAt != null,
    );

    final dosesThisWeek = completedRecords.where((record) {
      final completedAt = record.completedAt!;

      return !completedAt.isBefore(startOfWeek) &&
          !completedAt.isAfter(currentTime);
    }).length;

    final dosesThisMonth = completedRecords.where((record) {
      final completedAt = record.completedAt!;

      return !completedAt.isBefore(startOfMonth) &&
          !completedAt.isAfter(currentTime);
    }).length;

    final weightEntriesThisWeek = weightRecords.where((record) {
      return !record.recordedAt.isBefore(startOfWeek) &&
          !record.recordedAt.isAfter(currentTime);
    }).length;

    final weightEntriesThisMonth = weightRecords.where((record) {
      return !record.recordedAt.isBefore(startOfMonth) &&
          !record.recordedAt.isAfter(currentTime);
    }).length;

    return ActivityAnalytics(
      dosesThisWeek: dosesThisWeek,
      dosesThisMonth: dosesThisMonth,
      weightEntriesThisWeek: weightEntriesThisWeek,
      weightEntriesThisMonth: weightEntriesThisMonth,
    );
  }

  double? _weightChangeOverPeriod(
    List<WeightRecord> sorted,
    DateTime latestDate,
    Duration period,
  ) {
    if (sorted.length < 2) {
      return null;
    }

    final cutoff = latestDate.subtract(period);

    WeightRecord? baseline;

    for (final record in sorted) {
      if (!record.recordedAt.isAfter(cutoff)) {
        baseline = record;
      } else {
        break;
      }
    }

    baseline ??= sorted.first;

    final latest = sorted.last;

    if (baseline.id == latest.id) {
      return null;
    }

    return latest.weight - baseline.weight;
  }

  _DoseStreakResult _calculateStreaks(List<DoseRecord> sortedRecords) {
    var longest = 0;
    var running = 0;

    for (final record in sortedRecords) {
      if (record.status == DoseRecordStatus.taken) {
        running++;

        if (running > longest) {
          longest = running;
        }
      } else {
        running = 0;
      }
    }

    return _DoseStreakResult(current: running, longest: longest);
  }

  DateTime _startOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);

    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }
}

class _DoseStreakResult {
  const _DoseStreakResult({required this.current, required this.longest});

  final int current;
  final int longest;
}
