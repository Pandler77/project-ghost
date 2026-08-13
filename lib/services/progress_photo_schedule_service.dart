import '../models/progress_photo_session.dart';
import '../models/tracking_preferences.dart';

class ProgressPhotoScheduleStatus {
  const ProgressPhotoScheduleStatus({
    required this.isEnabled,
    required this.isDue,
    required this.isCompleteForPeriod,
    required this.nextDueDate,
    required this.lastSession,
  });

  final bool isEnabled;
  final bool isDue;
  final bool isCompleteForPeriod;
  final DateTime? nextDueDate;
  final ProgressPhotoSession? lastSession;
}

class ProgressPhotoScheduleService {
  ProgressPhotoScheduleStatus getStatus({
    required TrackingPreferences preferences,
    required List<ProgressPhotoSession> sessions,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();

    if (!preferences.trackPhotos) {
      return ProgressPhotoScheduleStatus(
        isEnabled: false,
        isDue: false,
        isCompleteForPeriod: false,
        nextDueDate: null,
        lastSession: sessions.isEmpty ? null : sessions.first,
      );
    }

    final sortedSessions = List<ProgressPhotoSession>.from(sessions)
      ..sort((first, second) => second.recordedAt.compareTo(first.recordedAt));

    final lastSession = sortedSessions.isEmpty ? null : sortedSessions.first;

    if (lastSession == null) {
      return const ProgressPhotoScheduleStatus(
        isEnabled: true,
        isDue: true,
        isCompleteForPeriod: false,
        nextDueDate: null,
        lastSession: null,
      );
    }

    final nextDueDate = _nextDueDate(
      lastSession.recordedAt,
      preferences.photoFrequency,
    );

    final isDue = !_dateOnly(currentTime).isBefore(_dateOnly(nextDueDate));

    return ProgressPhotoScheduleStatus(
      isEnabled: true,
      isDue: isDue,
      isCompleteForPeriod: !isDue,
      nextDueDate: nextDueDate,
      lastSession: lastSession,
    );
  }

  DateTime _nextDueDate(DateTime lastSessionDate, TrackingFrequency frequency) {
    final date = _dateOnly(lastSessionDate);

    return switch (frequency) {
      TrackingFrequency.daily => date.add(const Duration(days: 1)),
      TrackingFrequency.weekly => date.add(const Duration(days: 7)),
      TrackingFrequency.monthly => _addOneMonthClamped(date),
    };
  }

  DateTime _addOneMonthClamped(DateTime date) {
    final targetYear = date.month == 12 ? date.year + 1 : date.year;

    final targetMonth = date.month == 12 ? 1 : date.month + 1;

    final lastDayOfTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;

    final targetDay = date.day > lastDayOfTargetMonth
        ? lastDayOfTargetMonth
        : date.day;

    return DateTime(targetYear, targetMonth, targetDay);
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
