class BodyMetrics {
  const BodyMetrics._();

  static double? calculateBmi({
    required double weightKg,
    required double height,
  }) {
    final heightMeters = normalizeHeight(height);
    if (weightKg <= 0 || heightMeters == null) return null;
    return weightKg / (heightMeters * heightMeters);
  }

  static double? normalizeHeight(double height) {
    final heightMeters = height > 3 ? height / 100 : height;
    if (heightMeters < 0.5 || heightMeters > 3) return null;
    return heightMeters;
  }

  static String categoryForBmi(double bmi) {
    if (bmi < 18.5) return 'نحيف';
    if (bmi < 25) return 'طبيعي';
    if (bmi < 30) return 'وزن زائد';
    return 'سمنة';
  }
}
