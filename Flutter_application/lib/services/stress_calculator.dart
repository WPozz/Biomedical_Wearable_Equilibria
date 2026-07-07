// Stress Calculator
class DailyRawData {
  String shortLabel;
  double sleepHours;
  double heartRate;
  double steps;
  Map<String, double> heartRateZoneMinutes;

  DailyRawData({
    required this.shortLabel,
    this.sleepHours = 0,
    this.heartRate = 0,
    this.steps = 0,
    Map<String, double>? heartRateZoneMinutes,
  }) : heartRateZoneMinutes = heartRateZoneMinutes ?? {};
}

abstract class StressCalculator {
  static const double _baseStress = 35.0;

  // Sleep
  static const double _idealSleepHours = 8.0;
  static const double _sleepPenaltyPerHour = 7.0;
  static const double _missingDataSleepPenalty = 8.0;

  // HR
  static const double _restingHrThreshold = 65.0;
  static const double _hrPenaltyFactor = 1.8;

  // Cap for HR penalty
  static const double _maxHrPenalty = 25.0;

  // Discount on the HR penalty proportional to the day's TRIMP
  static const double _hrDiscountPerTrimpPoint = 0.004;

  // Maximum possible discount on HR penalty
  static const double _maxHrDiscount = 0.6;

  // Steps
  static const double _activityReliefPer1000Steps = 0.6;
  static const double _maxStepsRelief = 9.0;
  
  // Exercises -- Trimp
  static const Map<String, double> _trimpZoneWeights = {
    'outOfZone': 1.0,
    'fatBurn': 2.0,
    'cardio': 3.0,
    'peak': 4.0,
  };

  static const double _trimpToReliefScale = 0.13;
  static const double _maxExerciseRelief = 15.0;

  static double _calculateDailyTrimp(Map<String, double> zoneMinutes) {
    double trimp = 0.0;
    zoneMinutes.forEach((zone, minutes) {
      final double weight = _trimpZoneWeights[zone] ?? 0.0;
      trimp += minutes * weight;
    });
    return trimp;
  }

  static double calculateDailyStress(DailyRawData raw) {
    final bool hasExercise = raw.heartRateZoneMinutes.values.any((v) => v > 0);

    if (raw.sleepHours == 0 && raw.heartRate == 0 && raw.steps == 0 && !hasExercise) {
      return 0.0;
    }

    double sleepPenalty;
    if (raw.sleepHours > 0) {
      sleepPenalty = (_idealSleepHours - raw.sleepHours) * _sleepPenaltyPerHour;
      if (sleepPenalty < 0) sleepPenalty = 0;
    } else {
      sleepPenalty = _missingDataSleepPenalty;
    }

    final double dailyTrimp = _calculateDailyTrimp(raw.heartRateZoneMinutes);

    double hrPenalty = 0.0;
    if (raw.heartRate > _restingHrThreshold) {
      hrPenalty = (raw.heartRate - _restingHrThreshold) * _hrPenaltyFactor;
      hrPenalty = hrPenalty.clamp(0.0, _maxHrPenalty);
      if (dailyTrimp > 0) {
        final double discount =
            (dailyTrimp * _hrDiscountPerTrimpPoint).clamp(0.0, _maxHrDiscount);
        hrPenalty = hrPenalty * (1 - discount);
      }
    }

    final double stepsRelief = ((raw.steps / 1000.0) * _activityReliefPer1000Steps)
        .clamp(0.0, _maxStepsRelief);

    final double exerciseRelief = (dailyTrimp * _trimpToReliefScale)
        .clamp(0.0, _maxExerciseRelief);

    final double finalStress = _baseStress + sleepPenalty + hrPenalty
        - stepsRelief - exerciseRelief;

    return finalStress.clamp(0.0, 100.0).roundToDouble();
  }

  static Map<String, double> calculateStressForDays(
      List<DailyRawData> rawDataList) {
    return {
      for (final raw in rawDataList)
        raw.shortLabel: calculateDailyStress(raw),
    };
  }
}