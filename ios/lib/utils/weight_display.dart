import '../models/measurement_system.dart';
import 'measurement_converter.dart';

class WeightDisplay {
  const WeightDisplay._();

  static double displayValue(double pounds, MeasurementSystem system) {
    return switch (system) {
      MeasurementSystem.imperial => pounds,
      MeasurementSystem.metric => MeasurementConverter.poundsToKilograms(
        pounds,
      ),
    };
  }

  static double storageValue(double enteredValue, MeasurementSystem system) {
    return switch (system) {
      MeasurementSystem.imperial => enteredValue,
      MeasurementSystem.metric => MeasurementConverter.kilogramsToPounds(
        enteredValue,
      ),
    };
  }

  static String unit(MeasurementSystem system) {
    return switch (system) {
      MeasurementSystem.imperial => 'lb',
      MeasurementSystem.metric => 'kg',
    };
  }

  static String format(
    double pounds,
    MeasurementSystem system, {
    int decimals = 1,
  }) {
    final value = displayValue(pounds, system);

    return '${value.toStringAsFixed(decimals)} ${unit(system)}';
  }
}
