import 'package:flutter_test/flutter_test.dart';
import 'package:shadowdev/features/body/body_metrics.dart';

void main() {
  group('BodyMetrics', () {
    test('calculates BMI and category for a 100 kg adult', () {
      final bmi = BodyMetrics.calculateBmi(weightKg: 100, height: 1.75);

      expect(bmi, closeTo(32.65, 0.01));
      expect(BodyMetrics.categoryForBmi(bmi!), 'سمنة');
    });

    test('accepts height stored in centimeters', () {
      final bmi = BodyMetrics.calculateBmi(weightKg: 100, height: 175);

      expect(bmi, closeTo(32.65, 0.01));
    });

    test('uses standard BMI category boundaries', () {
      expect(BodyMetrics.categoryForBmi(18.4), 'نحيف');
      expect(BodyMetrics.categoryForBmi(18.5), 'طبيعي');
      expect(BodyMetrics.categoryForBmi(25), 'وزن زائد');
      expect(BodyMetrics.categoryForBmi(30), 'سمنة');
    });

    test('does not calculate BMI without a plausible height or weight', () {
      expect(BodyMetrics.calculateBmi(weightKg: 100, height: 0), isNull);
      expect(BodyMetrics.calculateBmi(weightKg: 0, height: 1.75), isNull);
      expect(BodyMetrics.calculateBmi(weightKg: 100, height: 1750), isNull);
    });
  });
}
