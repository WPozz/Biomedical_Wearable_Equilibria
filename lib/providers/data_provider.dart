import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_provider.dart';
import '../models/metric_point.dart';

// Questo è il provider per i dati, che gestisce le chiamate REST per ottenere i dati di home e trends. 
// Dipende da AuthProvider per l'accesso al token.

class DataProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  final String _baseUrl = 'https://impact.dei.unipd.it/bwthw';

  // Username del paziente di cui monitorare i dati
  static const String _patientUsername = 'Jpefaq6m58';

  bool isLoading = false;
  int totalSteps = 0;
  double totalCalories = 0.0;
  double totalDistance = 0.0;

  DataProvider({required this.authProvider});

  // Scarica i dati aggregati di un giorno specifico
  Future<void> fetchDailyData(String day) async {
    if (!authProvider.isAuthenticated) return;

    isLoading = true;
    notifyListeners();

    await _fetchMetric(_patientUsername, day, 'steps',    (v) => totalSteps = v.toInt());
    await _fetchMetric(_patientUsername, day, 'calories', (v) => totalCalories = v);
    await _fetchMetric(_patientUsername, day, 'distance', (v) => totalDistance = v);

    isLoading = false;
    notifyListeners();
  }

  // Metriche che si sommano (non si fanno la media)
static const _sumMetrics = {'steps', 'calories', 'distance', 'exercise'};

Future<List<MetricPoint>> fetchMetricRange(
    String metric, String startDate, String endDate) async {
  if (!authProvider.isAuthenticated) return [];
  
  final url = Uri.parse(
      '$_baseUrl/data/v1/$metric/patients/$_patientUsername/daterange/start_date/$startDate/end_date/$endDate/');

  final response = await _makeAuthenticatedGetRequest(url);

  if (response != null && response.statusCode == 200) {
    try {
      final jsonResponse = jsonDecode(response.body);
      final dynamic dataField = jsonResponse['data'];

      // Raccogliamo i valori raggruppati per data
      final Map<String, List<double>> byDay = {};

      if (dataField is List) {
        // Formato daterange: [{"date": "...", "data": [...]}, ...]
        for (final dayObj in dataField) {
          final String date = dayObj['date'].toString();

          // Sleep: data è un oggetto, non una lista
          if (metric == 'sleep') {
            final dynamic sleepData = dayObj['data'];
            if (sleepData != null) {
              final double minutes =
                  double.tryParse(sleepData['timeInBed'].toString()) ?? 0;
              byDay[date] = [minutes / 60.0];
            }
          } else {
            // Tutte le altre metriche
            final List<dynamic> dayData = dayObj['data'] as List;
            byDay[date] = dayData
                .map((e) => double.tryParse(e['value'].toString()) ?? 0.0)
                .toList();
          }
        }
      } else if (dataField is Map) {
        // Formato alternativo piatto: {"data": [...]}
        final List<dynamic> flat = dataField['data'] as List;
        for (final entry in flat) {
          final String time = entry['time'].toString();
          final String date =
              time.length >= 10 ? time.substring(0, 10) : startDate;
          byDay.putIfAbsent(date, () => []);
          byDay[date]!
              .add(double.tryParse(entry['value'].toString()) ?? 0.0);
        }
      }

      print('fetchMetricRange [$metric]: ${byDay.length} giorni');

      final bool useSum = _sumMetrics.contains(metric);

      // Un punto per giorno (somma o media a seconda della metrica)
      final points = byDay.entries.map((entry) {
        final nonZero =
            entry.value.where((v) => v > 0).toList();
        final double agg = nonZero.isEmpty
            ? 0
            : useSum
                ? nonZero.reduce((a, b) => a + b)
                : nonZero.reduce((a, b) => a + b) / nonZero.length;

        return MetricPoint(
          shortLabel: entry.key.substring(5), // MM-DD
          fullLabel: entry.key,
          value: double.parse(agg.toStringAsFixed(1)),
        );
      }).toList()
        ..sort((a, b) => a.fullLabel.compareTo(b.fullLabel));

      return points;
    } catch (e, stack) {
      print('fetchMetricRange parse ERROR: $e');
      print(stack);
      return [];
    }
  }
  return [];
}

  // Scarica e somma i valori di una singola metrica per un giorno
  Future<void> _fetchMetric(
      String patientUsername,
      String day,
      String metric,
      Function(double) onDataParsed) async {
    final url = Uri.parse(
        '$_baseUrl/data/v1/$metric/patients/$patientUsername/day/$day/');

    final response = await _makeAuthenticatedGetRequest(url);

    if (response != null && response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final List<dynamic> dataList = jsonResponse['data']['data'];

      double sum = 0.0;
      for (var entry in dataList) {
        sum += double.parse(entry['value'].toString());
      }
      onDataParsed(sum);
    }
  }
  // Metodo per singolo giorno (usa /day/ invece di /daterange/)
Future<List<MetricPoint>> fetchSingleDayMetric(
    String metric, String day) async {
  if (!authProvider.isAuthenticated) return [];

  final url = Uri.parse(
      '$_baseUrl/data/v1/$metric/patients/$_patientUsername/day/$day/');
  final response = await _makeAuthenticatedGetRequest(url);

  if (response != null && response.statusCode == 200) {
    try {
      final jsonResponse = jsonDecode(response.body);

      // Sleep: struttura completamente diversa
      if (metric == 'sleep') {
        final dynamic sleepObj = jsonResponse['data']['data'];
        if (sleepObj == null) return [];
        // timeInBed è in minuti
        final double minutes =
            double.tryParse(sleepObj['timeInBed'].toString()) ?? 0;
        final double hours = minutes / 60.0;
        return [
          MetricPoint(
            shortLabel: day.substring(5), // MM-DD
            fullLabel: day,
            value: double.parse(hours.toStringAsFixed(1)),
          )
        ];
      }

      // Tutte le altre metriche: lista di {time, value}
      final List<dynamic> raw = jsonResponse['data']['data'];
      final filtered = raw
          .where((e) => (double.tryParse(e['value'].toString()) ?? 0) > 0)
          .toList();

      const int maxPoints = 80;
      final List<dynamic> sampled = filtered.length > maxPoints
          ? [
              for (int i = 0;
                  i < filtered.length;
                  i += (filtered.length / maxPoints).ceil())
                filtered[i]
            ]
          : filtered;

      return sampled
          .map((e) => MetricPoint(
                shortLabel: e['time'].toString().substring(0, 5),
                fullLabel: '$day ${e['time']}',
                value: double.tryParse(e['value'].toString()) ?? 0,
              ))
          .toList();
    } catch (e, stack) {
      print('fetchSingleDayMetric [$metric] ERROR: $e');
      print(stack);
      return [];
    }
  }
  return [];
}
  // Helper: esegue una GET autenticata, gestendo il refresh del token se scaduto
  Future<http.Response?> _makeAuthenticatedGetRequest(Uri url) async {
    var response = await http.get(
      url,
      headers: {'Authorization': 'Bearer ${authProvider.accessToken}'},
    );

    print("STATUS CODE: ${response.statusCode}");
    print("RESPONSE BODY: ${response.body}");

    if (response.statusCode == 401 || response.statusCode == 403) {
      final bool refreshed = await authProvider.refresh();
      if (refreshed) {
        response = await http.get(
          url,
          headers: {'Authorization': 'Bearer ${authProvider.accessToken}'},
        );
      }
    }
    return response;
  }
  // --- CALCOLO DELLO STRESS INDEX PROXY ---

  // Metodo per calcolare lo stress su un range di date
  Future<List<MetricPoint>> fetchCalculatedStressRange(String startDate, String endDate) async {
    // 1. Scarichiamo i dati necessari in parallelo per ottimizzare i tempi
    final results = await Future.wait([
      fetchMetricRange('sleep', startDate, endDate),
      fetchMetricRange('heart_rate', startDate, endDate),
      fetchMetricRange('steps', startDate, endDate),
    ]);

    final List<MetricPoint> sleepData = results[0];
    final List<MetricPoint> hrData = results[1];
    final List<MetricPoint> stepsData = results[2];

    // 2. Raggruppiamo i dati per data (fullLabel)
    final Map<String, _DailyRawData> dailyDataMap = {};
    
    void populateMap(List<MetricPoint> data, void Function(_DailyRawData, double) assigner) {
      for (var point in data) {
        dailyDataMap.putIfAbsent(point.fullLabel, () => _DailyRawData(shortLabel: point.shortLabel));
        assigner(dailyDataMap[point.fullLabel]!, point.value);
      }
    }

    populateMap(sleepData, (d, v) => d.sleepHours = v);
    populateMap(hrData, (d, v) => d.heartRate = v);
    populateMap(stepsData, (d, v) => d.steps = v);

    // 3. Applichiamo la formula Proxy IUSM per ogni giorno
    final List<MetricPoint> stressPoints = [];
    
    dailyDataMap.forEach((fullLabel, raw) {
      double stressValue = _calculateDailyStressLogic(raw);
      stressPoints.add(MetricPoint(
        shortLabel: raw.shortLabel,
        fullLabel: fullLabel,
        value: stressValue,
      ));
    });

    // Ordiniamo cronologicamente
    stressPoints.sort((a, b) => a.fullLabel.compareTo(b.fullLabel));
    return stressPoints;
  }

  // Metodo per calcolare lo stress su un singolo giorno (per la vista DAY)
  Future<List<MetricPoint>> fetchCalculatedStressSingleDay(String day) async {
    // Per un singolo giorno, calcoliamo un unico valore aggregato.
    // L'API del giorno singolo ritorna i dati divisi per ore, dobbiamo prima aggregarli.
    
    final results = await Future.wait([
      fetchSingleDayMetric('sleep', day), // Ritorna già aggregato
      fetchMetricRange('heart_rate', day, day), // Usiamo range per avere la media giornaliera facilmente
      fetchMetricRange('steps', day, day),      // Usiamo range per avere la somma giornaliera
    ]);

    double sleepHours = results[0].isNotEmpty ? results[0].first.value : 0.0;
    double hrAvg = results[1].isNotEmpty ? results[1].first.value : 0.0;
    double totalSteps = results[2].isNotEmpty ? results[2].first.value : 0.0;

    final raw = _DailyRawData(shortLabel: day)..sleepHours = sleepHours..heartRate = hrAvg..steps = totalSteps;
    double stressValue = _calculateDailyStressLogic(raw);

    return [
      MetricPoint(shortLabel: day, fullLabel: day, value: stressValue)
    ];
  }

  // Il vero motore matematico (La formula Proxy)
  double _calculateDailyStressLogic(_DailyRawData raw) {
    // Se non abbiamo dati, ritorniamo 0 (o un valore neutro)
    if (raw.sleepHours == 0 && raw.heartRate == 0 && raw.steps == 0) return 0.0;

    double baseStress = 20.0;

    // 1. Penalità Sonno (Meno di 8 ore aumenta lo stress)
    double sleepPenalty = 0.0;
    if (raw.sleepHours > 0) {
      sleepPenalty = (8.0 - raw.sleepHours) * 10.0;
      if (sleepPenalty < 0) sleepPenalty = 0; // Nessun bonus per chi dorme 12 ore
    } else {
      sleepPenalty = 30.0; // Penalità fissa se dato mancante
    }

    // 2. Carico Simpatico (HR medio alto)
    double hrPenalty = 0.0;
    if (raw.heartRate > 65.0) {
      hrPenalty = (raw.heartRate - 65.0) * 0.8;
    }

    // 3. Gating Contestuale (I passi riducono il peso dell'HR alto)
    double activityRelief = (raw.steps / 1000.0) * 2.0;

    double finalStress = baseStress + sleepPenalty + hrPenalty - activityRelief;

    // Assicuriamoci che resti nel range 0-100
    return finalStress.clamp(0.0, 100.0).roundToDouble();
  }
}
class _DailyRawData {
  String shortLabel;
  double sleepHours = 0;
  double heartRate = 0;
  double steps = 0;

  _DailyRawData({required this.shortLabel});
}