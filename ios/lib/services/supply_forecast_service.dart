import '../models/inventory_item.dart';
import '../models/protocol.dart';
import '../models/schedule_type.dart';
import '../models/supply_forecast.dart';

class SupplyForecastService {
  const SupplyForecastService();

  SupplyForecast calculate({
    required InventoryItem item,
    required Protocol protocol,
    required double totalRemaining,
    required int unopenedContainerCount,
  }) {
    final usagePerDay = _dailyUsage(protocol);
    final now = DateTime.now();

    if (usagePerDay <= 0) {
      return SupplyForecast(
        totalRemaining: totalRemaining,
        averageDailyUsage: 0,
        daysRemaining: 0,
        depletionDate: now,
        reorderDate: now,
        percentRemaining: _supplyProgress(
          item: item,
          totalRemaining: totalRemaining,
        ),
        status: SupplyForecastStatus.unavailable,
      );
    }

    if (totalRemaining <= 0) {
      return SupplyForecast(
        totalRemaining: 0,
        averageDailyUsage: usagePerDay,
        daysRemaining: 0,
        depletionDate: now,
        reorderDate: now,
        percentRemaining: 0,
        status: SupplyForecastStatus.outOfStock,
      );
    }

    final daysRemaining = (totalRemaining / usagePerDay).floor();
    final depletionDate = now.add(Duration(days: daysRemaining));
    final reorderDate = depletionDate.subtract(
      Duration(days: item.shippingDays),
    );

    final status = _statusFor(
      item: item,
      totalRemaining: totalRemaining,
      unopenedContainerCount: unopenedContainerCount,
      daysRemaining: daysRemaining,
    );

    return SupplyForecast(
      totalRemaining: totalRemaining,
      averageDailyUsage: usagePerDay,
      daysRemaining: daysRemaining,
      depletionDate: depletionDate,
      reorderDate: reorderDate,
      percentRemaining: _supplyProgress(
        item: item,
        totalRemaining: totalRemaining,
      ),
      status: status,
    );
  }

  SupplyForecastStatus _statusFor({
    required InventoryItem item,
    required double totalRemaining,
    required int unopenedContainerCount,
    required int daysRemaining,
  }) {
    if (totalRemaining <= 0) {
      return SupplyForecastStatus.outOfStock;
    }

    if (daysRemaining <= item.shippingDays) {
      return SupplyForecastStatus.critical;
    }

    final reorderWindow = item.shippingDays + 14;

    if (daysRemaining <= reorderWindow ||
        unopenedContainerCount <= item.lowStockThreshold) {
      return SupplyForecastStatus.reorderSoon;
    }

    return SupplyForecastStatus.healthy;
  }

  double _supplyProgress({
    required InventoryItem item,
    required double totalRemaining,
  }) {
    final capacity = item.supplyCapacity;

    if (capacity <= 0 || totalRemaining <= 0) {
      return 0;
    }

    return (totalRemaining / capacity).clamp(0.0, 1.0);
  }

  double _dailyUsage(Protocol protocol) {
    final dose = protocol.doseAmount;

    if (dose <= 0) {
      return 0;
    }

    final schedule = protocol.schedule;

    switch (schedule.type) {
      case ScheduleType.daily:
        return dose;
      case ScheduleType.everyXDays:
        final intervalDays = schedule.intervalDays ?? 1;
        if (intervalDays <= 0) {
          return 0;
        }
        return dose / intervalDays;
      case ScheduleType.weekly:
        return dose / 7.0;
      case ScheduleType.specificDays:
        final dosesPerWeek = schedule.specificWeekdays.length;
        if (dosesPerWeek <= 0) {
          return 0;
        }
        return (dose * dosesPerWeek) / 7.0;
      case ScheduleType.monthly:
        return dose / 30.0;
    }
  }
}
