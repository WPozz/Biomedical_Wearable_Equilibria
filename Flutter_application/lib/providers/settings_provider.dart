import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _langKey = 'language_code';
  
  static const String _notifEnabledKey = 'notif_enabled';
  static const String _notifBreakKey   = 'notif_break';
  static const String _notifWaterKey   = 'notif_water';
  static const String _notifGoalsKey   = 'notif_goals';
  static const String _shareHRKey      = 'share_hr_data';

  static const String _customGoalsKey = 'custom_goals_enabled';
  static const String _sleepHoursKey  = 'sleep_hours';
  static const String _sleepMinsKey   = 'sleep_mins';
  static const String _stepsKey       = 'steps_goal';

  static const String _weightUnitKey   = 'weight_unit';
  static const String _distanceUnitKey = 'distance_unit';

  Locale _locale = const Locale('en');

  bool _notificationsEnabled = true;
  bool _breakReminder        = true;
  bool _hydrationReminder    = false;
  bool _goalsNotification    = true;
  bool _shareHRData          = false;
  bool _customGoalsEnabled = true;
  int  _sleepHours   = 8;
  int  _sleepMinutes = 0;
  int  _steps        = 10000;

  String _weightUnit   = 'kg';
  String _distanceUnit = 'km';

  Locale get locale    => _locale;
  bool get isItalian   => _locale.languageCode == 'it';

  bool get notificationsEnabled => _notificationsEnabled;
  bool get breakReminder        => _breakReminder;
  bool get hydrationReminder    => _hydrationReminder;
  bool get goalsNotification    => _goalsNotification;
  bool get shareHRData          => _shareHRData;

  bool   get customGoalsEnabled => _customGoalsEnabled;
  int    get sleepHours         => _sleepHours;
  int    get sleepMinutes       => _sleepMinutes;
  int    get steps              => _steps;
  String get weightUnit         => _weightUnit;
  String get distanceUnit       => _distanceUnit;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _locale = Locale(prefs.getString(_langKey) ?? 'en');

    _notificationsEnabled = prefs.getBool(_notifEnabledKey) ?? true;
    _breakReminder        = prefs.getBool(_notifBreakKey)   ?? true;
    _hydrationReminder    = prefs.getBool(_notifWaterKey)   ?? false;
    _goalsNotification    = prefs.getBool(_notifGoalsKey)   ?? true;
    _shareHRData          = prefs.getBool(_shareHRKey)      ?? false; 

    _customGoalsEnabled = prefs.getBool(_customGoalsKey) ?? true;
    _sleepHours   = prefs.getInt(_sleepHoursKey) ?? 8;
    _sleepMinutes = prefs.getInt(_sleepMinsKey)  ?? 0;
    _steps        = prefs.getInt(_stepsKey)      ?? 10000;

    _weightUnit   = prefs.getString(_weightUnitKey)   ?? 'kg';
    _distanceUnit = prefs.getString(_distanceUnitKey) ?? 'km';

    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, locale.languageCode);
  }

  Future<void> toggleLanguage() async {
    await setLocale(isItalian ? const Locale('en') : const Locale('it'));
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    if (!value) {
      _breakReminder     = false;
      _hydrationReminder = false;
      _goalsNotification = false;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifEnabledKey, value);
    if (!value) {
      await prefs.setBool(_notifBreakKey, false);
      await prefs.setBool(_notifWaterKey, false);
      await prefs.setBool(_notifGoalsKey, false);
    }
  }

  Future<void> setBreakReminder(bool value) async {
    _breakReminder = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifBreakKey, value);
  }

  Future<void> setHydrationReminder(bool value) async {
    _hydrationReminder = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifWaterKey, value);
  }

  Future<void> setGoalsNotification(bool value) async {
    _goalsNotification = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifGoalsKey, value);
  }

  Future<void> setShareHRData(bool value) async {
    _shareHRData = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_shareHRKey, value);
  }

  Future<void> setCustomGoalsEnabled(bool value) async {
    _customGoalsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_customGoalsKey, value);
  }

  Future<void> setSleepGoal(int hours, int minutes) async {
    _sleepHours   = hours;
    _sleepMinutes = minutes;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sleepHoursKey, hours);
    await prefs.setInt(_sleepMinsKey, minutes);
  }

  Future<void> setStepsGoal(int steps) async {
    _steps = steps;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stepsKey, steps);
  }
}