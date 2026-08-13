enum SupplyForecastStatus {
  healthy,
  reorderSoon,
  critical,
  outOfStock,
  unavailable,
}

class SupplyForecast {
  const SupplyForecast({
    required this.totalRemaining,
    required this.averageDailyUsage,
    required this.daysRemaining,
    required this.depletionDate,
    required this.reorderDate,
    required this.percentRemaining,
    required this.status,
  });

  final double totalRemaining;
  final double averageDailyUsage;
  final int daysRemaining;
  final DateTime depletionDate;
  final DateTime reorderDate;
  final double percentRemaining;
  final SupplyForecastStatus status;

  bool get shouldReorder {
    return status == SupplyForecastStatus.reorderSoon ||
        status == SupplyForecastStatus.critical ||
        status == SupplyForecastStatus.outOfStock;
  }

  bool get isCritical {
    return status == SupplyForecastStatus.critical ||
        status == SupplyForecastStatus.outOfStock;
  }

  String get statusLabel {
    return switch (status) {
      SupplyForecastStatus.healthy => 'Healthy',
      SupplyForecastStatus.reorderSoon => 'Reorder Soon',
      SupplyForecastStatus.critical => 'Critical',
      SupplyForecastStatus.outOfStock => 'Out of Stock',
      SupplyForecastStatus.unavailable => 'Unavailable',
    };
  }
}
