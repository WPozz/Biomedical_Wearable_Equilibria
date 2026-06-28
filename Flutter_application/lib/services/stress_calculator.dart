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
  static const double _baseStress = 40.0;

  // Sonno mancante o cattivo 
  static const double _idealSleepHours = 8.0;
  static const double _sleepPenaltyPerHour = 7.0;
  // Se dormi solo 5.5 ore, ti mancano 2.5 ore . L'algoritmo fa: 2.5 ore perse × 7.0 = +17.5 punti di stress aggiunti
  static const double _missingDataSleepPenalty = 8.0;

  static const double _restingHrThreshold = 65.0;
  static const double _hrPenaltyFactor = 1.8;
  // Se un giorno hai una media di 75 bpm, sei 10 battiti sopra la soglia. L'algoritmo fa: 10 bpm extra × 1.8 = +18 punti

  // Cap alla penalità HR pura 
  // Perché: la frequenza cardiaca MEDIA GIORNALIERA include anche i minuti
  // di un eventuale allenamento. Senza un limite, un giorno con
  // un'uscita in bici lunga può generare una hrPenalty altissima (es. 25-40
  // punti) che il relief da esercizio (_maxExerciseRelief = 15)
  // non riesce mai a controbilanciare. Risultato: i giorni con più sport
  // risultavano sistematicamente PIÙ stressanti dei giorni sedentari,
  // l'opposto di quanto l'app vuole comunicare.
  static const double _maxHrPenalty = 25.0;

  // Sconto sulla HR penalty proporzionale al TRIMP del giorno
  // Perché: anche con il cap sopra, un giorno con sport intenso parte
  // comunque da una hrPenalty più alta di un giorno sedentario (perché la
  // media HR del giorno è più alta). Per evitare che la sola hrPenalty
  // cappata "mangi" gran parte del relief da esercizio lasciando il giorno
  // sportivo comunque più stressante del feriale, scontiamo la hrPenalty in
  // proporzione al carico di allenamento registrato: più TRIMP, più
  // riconosciamo che l'HR elevata di quel giorno è dovuta (almeno in parte)
  // allo sport e non a un carico simpatico "negativo".
  static const double _hrDiscountPerTrimpPoint = 0.004;

  // Sconto massimo applicabile alla hrPenalty: anche con un TRIMP molto alto
  // (es. uscite molto lunghe), una quota minima di hrPenalty resta sempre.
  // Senza questo cap, sopra una certa soglia di TRIMP lo sconto arriva al
  // 100%, la hrPenalty si azzera del tutto, e la formula collassa sempre
  // sullo stesso valore minimo nei giorni con sport — perdendo qualunque
  // variazione utile a distinguere un allenamento moderato da uno intenso.
  static const double _maxHrDiscount = 0.6;

  static const double _activityReliefPer1000Steps = 0.6;
  static const double _maxStepsRelief = 8.0;
  // Limite massimo di punti di stress che puoi farti scalare semplicemente camminando.

  static const Map<String, double> _trimpZoneWeights = {
    'outOfZone': 1.0,
    'fatBurn': 2.0,
    'cardio': 3.0,
    'peak': 4.0,
  };

  static const double _trimpToReliefScale = 0.12;
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

    // TRIMP del giorno: calcolato prima della hrPenalty, perché ora serve
    // anche per scontare quest'ultima (oltre che per l'exerciseRelief).
    final double dailyTrimp = _calculateDailyTrimp(raw.heartRateZoneMinutes);

    double hrPenalty = 0.0;
    if (raw.heartRate > _restingHrThreshold) {
      hrPenalty = (raw.heartRate - _restingHrThreshold) * _hrPenaltyFactor;
      // Cap: la sola HR alta non può pesare più di _maxHrPenalty punti.
      hrPenalty = hrPenalty.clamp(0.0, _maxHrPenalty);
      // Sconto proporzionale al TRIMP: se quel giorno c'è stato sport,
      // parte dell'HR elevata è "spiegata" dall'allenamento, non da stress.
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