class MeasurementConverter {
  const MeasurementConverter._();

  static const double poundsPerKilogram = 2.2046226218;
  static const double centimetersPerInch = 2.54;

  static double poundsToKilograms(double pounds) {
    return pounds / poundsPerKilogram;
  }

  static double kilogramsToPounds(double kilograms) {
    return kilograms * poundsPerKilogram;
  }

  static double inchesToCentimeters(double inches) {
    return inches * centimetersPerInch;
  }

  static double centimetersToInches(double centimeters) {
    return centimeters / centimetersPerInch;
  }
}
