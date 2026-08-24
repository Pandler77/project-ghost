import '../models/dose_record.dart';
import '../models/measurement_system.dart';
import '../models/milestone_achievement.dart';
import '../models/profile.dart';
import '../models/weight_record.dart';
import '../utils/measurement_converter.dart';
import 'settings_service.dart';

class MilestoneService {
  MilestoneService({SettingsService? settingsService})
    : _settingsService = settingsService ?? SettingsService();

  final SettingsService _settingsService;

  static const List<int> _doseMilestones = [10, 25, 50, 100, 250, 500, 1000];

  // Canonical weight-loss milestone interval.
  // Weight is stored internally in pounds, so keeping one canonical interval
  // prevents duplicate milestone behavior if the user changes display units.
  static const double _weightLossIntervalPounds = 15;

  Future<void> evaluateWeightSave({
    required Profile profile,
    required List<WeightRecord> beforeRecords,
    required List<WeightRecord> afterRecords,
  }) async {
    if (!await _settingsService.getCelebrationsEnabled()) {
      return;
    }

    final startingWeight = profile.startingWeight;

    if (startingWeight == null || startingWeight <= 0 || afterRecords.isEmpty) {
      return;
    }

    final beforeLatest = _latestWeight(beforeRecords);
    final afterLatest = _latestWeight(afterRecords);

    if (afterLatest == null) {
      return;
    }

    final measurementSystem = await _settingsService.getMeasurementSystem();

    final awarded = await _settingsService.getAwardedMilestoneIds(profile.id);

    // Existing regular weight-loss milestones become the baseline.
    // Goal weight is intentionally NOT baseline-awarded here.
    if (beforeLatest != null) {
      final baselineIds = _weightMilestoneIdsAt(
        startingWeight: startingWeight,
        currentWeight: beforeLatest.weight,
      );

      final missingBaseline = baselineIds.difference(awarded);

      if (missingBaseline.isNotEmpty) {
        await _settingsService.addAwardedMilestoneIds(
          profile.id,
          missingBaseline,
        );

        awarded.addAll(missingBaseline);
      }
    }

    final goalWeight = profile.goalWeight;
    final goalId = 'goal-weight';

    final beforeReachedGoal =
        beforeLatest != null &&
        goalWeight != null &&
        goalWeight > 0 &&
        _goalReached(
          startingWeight: startingWeight,
          goalWeight: goalWeight,
          currentWeight: beforeLatest.weight,
        );

    final afterReachedGoal =
        goalWeight != null &&
        goalWeight > 0 &&
        _goalReached(
          startingWeight: startingWeight,
          goalWeight: goalWeight,
          currentWeight: afterLatest.weight,
        );

    // GOAL WEIGHT TAKES PRIORITY OVER NORMAL WEIGHT MILESTONES.
    if (!awarded.contains(goalId) && !beforeReachedGoal && afterReachedGoal) {
      final newLoss = startingWeight - afterLatest.weight;

      if (newLoss > 0) {
        final currentStep = (newLoss / _weightLossIntervalPounds).floor();

        if (currentStep > 0) {
          final crossedIds = <String>{
            for (var step = 1; step <= currentStep; step++)
              _weightLossId(step * _weightLossIntervalPounds),
          };

          await _settingsService.addAwardedMilestoneIds(profile.id, crossedIds);

          awarded.addAll(crossedIds);
        }
      }

      await _settingsService.addAwardedMilestoneIds(profile.id, {goalId});

      await _settingsService.enqueueMilestone(
        MilestoneAchievement(
          id: goalId,
          profileId: profile.id,
          kind: MilestoneKind.goalWeight,
          title: 'Goal reached!',
          message: 'You reached the goal weight you set in MODOSE.',
          achievedAt: DateTime.now(),
        ),
      );

      return;
    }

    final newLoss = startingWeight - afterLatest.weight;

    final previousLoss = beforeLatest == null
        ? 0.0
        : startingWeight - beforeLatest.weight;

    final currentStep = newLoss > 0
        ? (newLoss / _weightLossIntervalPounds).floor()
        : 0;

    final previousStep = previousLoss > 0
        ? (previousLoss / _weightLossIntervalPounds).floor()
        : 0;

    // Normal weight-loss milestones only run if goal weight was not reached
    // on this save.
    if (currentStep > previousStep && currentStep > 0) {
      final thresholdPounds = currentStep * _weightLossIntervalPounds;

      final milestoneId = _weightLossId(thresholdPounds);

      final crossedIds = <String>{
        for (var step = 1; step <= currentStep; step++)
          _weightLossId(step * _weightLossIntervalPounds),
      };

      await _settingsService.addAwardedMilestoneIds(profile.id, crossedIds);

      if (!awarded.contains(milestoneId)) {
        final displayAmount = _formatWeightLoss(
          thresholdPounds,
          measurementSystem,
        );

        await _settingsService.enqueueMilestone(
          MilestoneAchievement(
            id: milestoneId,
            profileId: profile.id,
            kind: MilestoneKind.weightLoss,
            title: '$displayAmount down!',
            message: 'Another milestone in the books.',
            achievedAt: DateTime.now(),
          ),
        );
      }
    }
  }

  Future<void> evaluateDoseSave({
    required Profile profile,
    required List<DoseRecord> beforeRecords,
    required List<DoseRecord> afterRecords,
  }) async {
    if (!await _settingsService.getCelebrationsEnabled()) {
      return;
    }

    final beforeCount = _takenCount(beforeRecords);
    final afterCount = _takenCount(afterRecords);

    if (afterCount <= beforeCount) {
      return;
    }

    final awarded = await _settingsService.getAwardedMilestoneIds(profile.id);

    // Treat all milestones already reached before this save as baseline.
    final baselineIds = <String>{
      for (final value in _doseMilestones)
        if (value <= beforeCount) _doseCountId(value),
    };

    final missingBaseline = baselineIds.difference(awarded);

    if (missingBaseline.isNotEmpty) {
      await _settingsService.addAwardedMilestoneIds(
        profile.id,
        missingBaseline,
      );
      awarded.addAll(missingBaseline);
    }

    int? crossedMilestone;

    for (final value in _doseMilestones) {
      if (value > beforeCount &&
          value <= afterCount &&
          !awarded.contains(_doseCountId(value))) {
        crossedMilestone = value;
      }
    }

    if (crossedMilestone == null) {
      return;
    }

    final crossedIds = <String>{
      for (final value in _doseMilestones)
        if (value <= afterCount) _doseCountId(value),
    };

    await _settingsService.addAwardedMilestoneIds(profile.id, crossedIds);

    await _settingsService.enqueueMilestone(
      MilestoneAchievement(
        id: _doseCountId(crossedMilestone),
        profileId: profile.id,
        kind: MilestoneKind.doseCount,
        title: '$crossedMilestone doses logged!',
        message:
            'MODOSE has tracked $crossedMilestone completed doses with you.',
        achievedAt: DateTime.now(),
      ),
    );
  }

  WeightRecord? _latestWeight(List<WeightRecord> records) {
    if (records.isEmpty) {
      return null;
    }

    final sorted = [...records]
      ..sort((first, second) => second.recordedAt.compareTo(first.recordedAt));

    return sorted.first;
  }

  int _takenCount(List<DoseRecord> records) {
    return records
        .where(
          (record) =>
              record.status == DoseRecordStatus.taken &&
              record.completedAt != null,
        )
        .length;
  }

  Set<String> _weightMilestoneIdsAt({
    required double startingWeight,
    required double currentWeight,
  }) {
    final loss = startingWeight - currentWeight;

    if (loss < _weightLossIntervalPounds) {
      return {};
    }

    final steps = (loss / _weightLossIntervalPounds).floor();

    return {
      for (var step = 1; step <= steps; step++)
        _weightLossId(step * _weightLossIntervalPounds),
    };
  }

  bool _goalReached({
    required double startingWeight,
    required double goalWeight,
    required double currentWeight,
  }) {
    if (goalWeight < startingWeight) {
      return currentWeight <= goalWeight;
    }

    if (goalWeight > startingWeight) {
      return currentWeight >= goalWeight;
    }

    return true;
  }

  String _weightLossId(double pounds) {
    return 'weight-loss-${pounds.round()}lb';
  }

  String _doseCountId(int count) {
    return 'dose-count-$count';
  }

  String _formatWeightLoss(double pounds, MeasurementSystem measurementSystem) {
    if (measurementSystem == MeasurementSystem.imperial) {
      return '${pounds.round()} lb';
    }

    final kilograms = MeasurementConverter.poundsToKilograms(pounds);

    return '${kilograms.toStringAsFixed(1)} kg';
  }
}

