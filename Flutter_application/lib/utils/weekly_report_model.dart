import 'package:flutter/material.dart';

class DailyStress {
  final DateTime date;
  final double stressIndex;

  const DailyStress({required this.date, required this.stressIndex});

  StressLevel get level {
    if (stressIndex <= 40) return StressLevel.low;
    if (stressIndex <= 65) return StressLevel.medium;
    return StressLevel.high;
  }
}

enum StressLevel { low, medium, high }

enum WeekPerformance { excellent, good, fair, poor }

extension WeekPerformanceLabels on WeekPerformance {
  String label(bool isItalian) {
    switch (this) {
      case WeekPerformance.excellent: return isItalian ? 'Eccellente' : 'Excellent';
      case WeekPerformance.good:      return isItalian ? 'Buona'      : 'Good';
      case WeekPerformance.fair:      return isItalian ? 'Discreta'   : 'Fair';
      case WeekPerformance.poor:      return isItalian ? 'Settimana difficile' : 'Tough week';
    }
  }

  Color get color {
    switch (this) {
      case WeekPerformance.excellent: return const Color(0xFF16A34A);
      case WeekPerformance.good:      return const Color(0xFFF59E0B);
      case WeekPerformance.fair:      return const Color(0xFFF97316);
      case WeekPerformance.poor:      return const Color(0xFFF87171);
    }
  }
}

class WeeklyReport {
  final DateTime weekStart;
  final DateTime weekEnd;
  final bool hasData;

  final String evaluationIt;
  final String evaluationEn;
  final String dateRangeIt;
  final String dateRangeEn;
  final int goalsAchieved;

  // Stress
  final double avgStressIndex;
  final List<DailyStress> dailyStress;
  final String mostStressfulDay;
  final String peakStressTimeRange;
  final int peakStressDaysCount;

  // Sleep
  final double avgSleepHours;
  final double prevAvgSleepHours;
  final double sleepStressCorrelation;
  final int missingSleepDays;
  final int missingSleepDaysPrev;

  // Movement (steps + exercises)
  final double avgDailySteps;
  final double prevAvgDailySteps;
  final int exerciseSessions;
  final double stepsStressCorrelation;

  // SPrevious week stress
  final double prevAvgStressIndex;

  // Goals
  final bool goalsEnabled;
  final int stepsGoalDaysReached;
  final int sleepGoalDaysReached;
  final int stepsGoalTarget;
  final double sleepGoalHours;

  const WeeklyReport({
    required this.weekStart,
    required this.weekEnd,
    required this.hasData,
    required this.evaluationIt,
    required this.evaluationEn,
    required this.dateRangeIt,
    required this.dateRangeEn,
    required this.goalsAchieved,
    required this.avgStressIndex,
    required this.dailyStress,
    required this.mostStressfulDay,
    required this.peakStressTimeRange,
    required this.peakStressDaysCount,
    required this.avgSleepHours,
    required this.prevAvgSleepHours,
    required this.sleepStressCorrelation,
    required this.avgDailySteps,
    required this.prevAvgDailySteps,
    required this.exerciseSessions,
    required this.stepsStressCorrelation,
    required this.prevAvgStressIndex,
    required this.goalsEnabled,
    required this.stepsGoalDaysReached,
    required this.sleepGoalDaysReached,
    required this.stepsGoalTarget,
    required this.sleepGoalHours,
    this.missingSleepDays = 0,
    this.missingSleepDaysPrev = 0,
  });

  WeekPerformance get performance {
    if (avgStressIndex <= 35) return WeekPerformance.excellent;
    if (avgStressIndex <= 52) return WeekPerformance.good;
    if (avgStressIndex <= 70) return WeekPerformance.fair;
    return WeekPerformance.poor;
  }

  double get sleepDeltaMin => (avgSleepHours - prevAvgSleepHours) * 60;
  double get stressDelta   => avgStressIndex - prevAvgStressIndex;
  double get stepsDelta    => avgDailySteps  - prevAvgDailySteps;

  bool get sleepDeltaReliable =>
      missingSleepDaysPrev < 7 && prevAvgSleepHours > 0;

  bool get hasExerciseData => exerciseSessions > 0;

  static const double correlationThreshold = 10.0;

  bool get sleepCorrelationSignificant =>
      sleepStressCorrelation.abs() >= correlationThreshold;

  bool get movementCorrelationSignificant =>
      stepsStressCorrelation.abs() >= correlationThreshold;

  factory WeeklyReport.empty({
    required DateTime weekStart,
    required DateTime weekEnd,
    required String dateRangeIt,
    required String dateRangeEn,
  }) {
    return WeeklyReport(
      weekStart: weekStart,
      weekEnd: weekEnd,
      hasData: false,
      evaluationIt: '–',
      evaluationEn: '–',
      dateRangeIt: dateRangeIt,
      dateRangeEn: dateRangeEn,
      goalsAchieved: 0,
      avgStressIndex: 0,
      dailyStress: const [],
      mostStressfulDay: 'N/A',
      peakStressTimeRange: 'N/A',
      peakStressDaysCount: 0,
      avgSleepHours: 0,
      prevAvgSleepHours: 0,
      sleepStressCorrelation: 0,
      avgDailySteps: 0,
      prevAvgDailySteps: 0,
      exerciseSessions: 0,
      stepsStressCorrelation: 0,
      prevAvgStressIndex: 0,
      goalsEnabled: false,
      stepsGoalDaysReached: 0,
      sleepGoalDaysReached: 0,
      stepsGoalTarget: 0,
      sleepGoalHours: 0,
      missingSleepDays: 0,
      missingSleepDaysPrev: 0,
    );
  }
}