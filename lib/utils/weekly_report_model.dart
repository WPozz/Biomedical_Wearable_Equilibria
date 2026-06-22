
// calcola la correlazione e mettla nel JSON!!!!!


import 'package:flutter/material.dart';

// ─ Dati per un singolo giorno ─

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

// ─ Performance settimanale ─

enum WeekPerformance { excellent, good, fair, poor }

extension WeekPerformanceLabels on WeekPerformance {
  String label(bool isItalian) {
    switch (this) {
      case WeekPerformance.excellent: return isItalian ? 'Eccellente' : 'Excellent';
      case WeekPerformance.good:      return isItalian ? 'Buona' : 'Good';
      case WeekPerformance.fair:      return isItalian ? 'Discreta' : 'Fair';
      case WeekPerformance.poor:      return isItalian ? 'Settimana difficile' : 'Tough week';
    }
  }

  Color get color {
    switch (this) {
      case WeekPerformance.excellent: return const Color(0xFF4ADE80);
      case WeekPerformance.good:      return const Color(0xFFF59E0B);
      case WeekPerformance.fair:      return const Color(0xFFF97316);
      case WeekPerformance.poor:      return const Color(0xFFF87171);
    }
  }
}

// ─ Report settimanale completo ─

class WeeklyReport {
  final DateTime weekStart;
  final DateTime weekEnd;
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

  // Sonno
  final double avgSleepHours;
  final double prevAvgSleepHours;
  final double sleepStressCorrelation;

  // Movimento
  final double avgDailySteps;
  final double prevAvgDailySteps;  
  final int exerciseSessions;
  final double stepsStressCorrelation;

  // Stress settimana precedente
  final double prevAvgStressIndex; 

  // Obiettivi
  final bool goalsEnabled;       
  final int stepsGoalDaysReached;
  final int sleepGoalDaysReached;
  final int stepsGoalTarget;
  final double sleepGoalHours;

  const WeeklyReport({
    required this.weekStart,
    required this.weekEnd,
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
  });

  WeekPerformance get performance {
    if (avgStressIndex <= 40) return WeekPerformance.excellent;
    if (avgStressIndex <= 60) return WeekPerformance.good;
    if (avgStressIndex <= 75) return WeekPerformance.fair;
    return WeekPerformance.poor;
  }

  double get sleepDeltaMin => (avgSleepHours - prevAvgSleepHours) * 60;
  double get stressDelta   => avgStressIndex - prevAvgStressIndex;
  double get stepsDelta    => avgDailySteps - prevAvgDailySteps;

  // Soglia minima perché la correlazione sia considerata significativa
  static const double correlationThreshold = 10.0;

  bool get sleepCorrelationSignificant => sleepStressCorrelation.abs() >= correlationThreshold;
  bool get stepsCorrelationSignificant => stepsStressCorrelation.abs() >= correlationThreshold;
}

// Dati finti

final List<WeeklyReport> mockReports = [
  // Settimana 1 – correlazioni chiare
  WeeklyReport(
    weekStart: DateTime(2026, 5, 11),
    weekEnd:   DateTime(2026, 5, 17),
    evaluationIt: 'Ottimo',
    evaluationEn: 'Excellent',
    dateRangeIt:  '11 Mag – 17 Mag 2026',
    dateRangeEn:  'May 11 – May 17 2026',
    goalsAchieved: 2,
    avgStressIndex: 34,
    prevAvgStressIndex: 51,
    dailyStress: [
      DailyStress(date: DateTime(2026, 5, 11), stressIndex: 28),
      DailyStress(date: DateTime(2026, 5, 12), stressIndex: 22),
      DailyStress(date: DateTime(2026, 5, 13), stressIndex: 61),
      DailyStress(date: DateTime(2026, 5, 14), stressIndex: 32),
      DailyStress(date: DateTime(2026, 5, 15), stressIndex: 44),
      DailyStress(date: DateTime(2026, 5, 16), stressIndex: 18),
      DailyStress(date: DateTime(2026, 5, 17), stressIndex: 14),
    ],
    mostStressfulDay: 'Wednesday',
    peakStressTimeRange: '14:00 – 16:00',
    peakStressDaysCount: 4,
    avgSleepHours: 7.2,
    prevAvgSleepHours: 6.85,
    sleepStressCorrelation: 22,
    avgDailySteps: 7400,
    prevAvgDailySteps: 6200,
    exerciseSessions: 3,
    stepsStressCorrelation: 38,
    goalsEnabled: true,
    stepsGoalDaysReached: 5,
    sleepGoalDaysReached: 4,
    stepsGoalTarget: 7000,
    sleepGoalHours: 7.0,
  ),
  // Settimana 2 – correlazioni deboli
  WeeklyReport(
    weekStart: DateTime(2026, 5, 4),
    weekEnd:   DateTime(2026, 5, 10),
    evaluationIt: 'Buono',
    evaluationEn: 'Good',
    dateRangeIt:  '4 Mag – 10 Mag 2026',
    dateRangeEn:  'May 04 – May 10 2026',
    goalsAchieved: 1,
    avgStressIndex: 51,
    prevAvgStressIndex: 72,
    dailyStress: [
      DailyStress(date: DateTime(2026, 5, 4),  stressIndex: 48),
      DailyStress(date: DateTime(2026, 5, 5),  stressIndex: 55),
      DailyStress(date: DateTime(2026, 5, 6),  stressIndex: 70),
      DailyStress(date: DateTime(2026, 5, 7),  stressIndex: 52),
      DailyStress(date: DateTime(2026, 5, 8),  stressIndex: 60),
      DailyStress(date: DateTime(2026, 5, 9),  stressIndex: 35),
      DailyStress(date: DateTime(2026, 5, 10), stressIndex: 38),
    ],
    mostStressfulDay: 'Wednesday',
    peakStressTimeRange: '15:00 – 17:00',
    peakStressDaysCount: 3,
    avgSleepHours: 6.85,
    prevAvgSleepHours: 6.5,
    sleepStressCorrelation: 5,
    avgDailySteps: 6200,
    prevAvgDailySteps: 4800,
    exerciseSessions: 2,
    stepsStressCorrelation: 7,
    goalsEnabled: true,
    stepsGoalDaysReached: 3,
    sleepGoalDaysReached: 3,
    stepsGoalTarget: 7000,
    sleepGoalHours: 7.0,
  ),
  // Settimana 3 – correlazione inversa
  WeeklyReport(
    weekStart: DateTime(2026, 4, 27),
    weekEnd:   DateTime(2026, 5, 3),
    evaluationIt: 'Migliorabile',
    evaluationEn: 'Fair',
    dateRangeIt:  '27 Apr – 3 Mag 2026',
    dateRangeEn:  'Apr 27 – May 03 2026',
    goalsAchieved: 0,
    avgStressIndex: 72,
    prevAvgStressIndex: 47,
    dailyStress: [
      DailyStress(date: DateTime(2026, 4, 27), stressIndex: 68),
      DailyStress(date: DateTime(2026, 4, 28), stressIndex: 75),
      DailyStress(date: DateTime(2026, 4, 29), stressIndex: 82),
      DailyStress(date: DateTime(2026, 4, 30), stressIndex: 70),
      DailyStress(date: DateTime(2026, 5, 1),  stressIndex: 78),
      DailyStress(date: DateTime(2026, 5, 2),  stressIndex: 55),
      DailyStress(date: DateTime(2026, 5, 3),  stressIndex: 60),
    ],
    mostStressfulDay: 'Tuesday',
    peakStressTimeRange: '09:00 – 11:00',
    peakStressDaysCount: 5,
    avgSleepHours: 5.9,
    prevAvgSleepHours: 6.4,
    sleepStressCorrelation: -15,
    avgDailySteps: 4800,
    prevAvgDailySteps: 6800,
    exerciseSessions: 1,
    stepsStressCorrelation: -12,
    goalsEnabled: true,
    stepsGoalDaysReached: 1,
    sleepGoalDaysReached: 1,
    stepsGoalTarget: 7000,
    sleepGoalHours: 7.0,
  ),
  // Settimana 4 – goals disabilitati
  WeeklyReport(
    weekStart: DateTime(2026, 4, 20),
    weekEnd:   DateTime(2026, 4, 26),
    evaluationIt: 'Buono',
    evaluationEn: 'Good',
    dateRangeIt:  '20 Apr – 26 Apr 2026',
    dateRangeEn:  'Apr 20 – Apr 26 2026',
    goalsAchieved: 0,
    avgStressIndex: 47,
    prevAvgStressIndex: 58,
    dailyStress: [
      DailyStress(date: DateTime(2026, 4, 20), stressIndex: 42),
      DailyStress(date: DateTime(2026, 4, 21), stressIndex: 50),
      DailyStress(date: DateTime(2026, 4, 22), stressIndex: 55),
      DailyStress(date: DateTime(2026, 4, 23), stressIndex: 44),
      DailyStress(date: DateTime(2026, 4, 24), stressIndex: 48),
      DailyStress(date: DateTime(2026, 4, 25), stressIndex: 40),
      DailyStress(date: DateTime(2026, 4, 26), stressIndex: 38),
    ],
    mostStressfulDay: 'Wednesday',
    peakStressTimeRange: '10:00 – 12:00',
    peakStressDaysCount: 3,
    avgSleepHours: 6.5,
    prevAvgSleepHours: 6.2,
    sleepStressCorrelation: 14,
    avgDailySteps: 6800,
    prevAvgDailySteps: 5900,
    exerciseSessions: 2,
    stepsStressCorrelation: 20,
    goalsEnabled: false,
    stepsGoalDaysReached: 0,
    sleepGoalDaysReached: 0,
    stepsGoalTarget: 7000,
    sleepGoalHours: 7.0,
  ),
];