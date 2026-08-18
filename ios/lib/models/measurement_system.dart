enum MeasurementSystem { imperial, metric }

extension MeasurementSystemX on MeasurementSystem {
  String get label {
    switch (this) {
      case MeasurementSystem.imperial:
        return 'Imperial';
      case MeasurementSystem.metric:
        return 'Metric';
    }
  }

  String get description {
    switch (this) {
      case MeasurementSystem.imperial:
        return 'lb, ft, in';
      case MeasurementSystem.metric:
        return 'kg, cm';
    }
  }

  String get weightUnit {
    switch (this) {
      case MeasurementSystem.imperial:
        return 'lb';
      case MeasurementSystem.metric:
        return 'kg';
    }
  }

  String get heightUnit {
    switch (this) {
      case MeasurementSystem.imperial:
        return 'ft / in';
      case MeasurementSystem.metric:
        return 'cm';
    }
  }
}
