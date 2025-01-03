import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:senti/hive/boxes.dart';
import 'package:senti/hive/settings.dart';

class SettingsProvider extends ChangeNotifier {
  final Box<Settings> settingsBox = Boxes.getSettings();

  Settings? _settings;

  Settings? get settings => _settings;

  SettingsProvider() {
    _settings = settingsBox.isNotEmpty ? settingsBox.getAt(0) : null;

    // Initialize settings if null
    if (_settings == null) {
      _settings = Settings(
        isDarkTheme: false,
        shouldSpeak: false,
        language: 'en',
        fontSize: 16.0,
        notificationsEnabled: true,
        privacy: false,
        selectedLLMProvider: 'gemini',
        sentimentAnalysisEnabled: false,
        preferredSentimentLanguage: 'en',
        llmModelSettings: {},
        availableLLMProviders: ['gemini', 'openai', 'ollama', 'llama'],
      );
      settingsBox.add(_settings!);
    }
  }

  void toggleSpeak({required bool value}) async {
    final settingsBox = await Hive.openBox<Settings>('settingsBox');
    final settings = settingsBox.get('mySettingsKey') ?? Settings();
    settings.shouldSpeak = value;
    await settingsBox.put('mySettingsKey', settings);
    notifyListeners();
  }

  void toggleNotifications({required bool value}) {
    if (_settings != null) {
      _settings!.notificationsEnabled = value;
      _settings!.save();
      notifyListeners();
    }
  }

  void toggleDarkMode({required bool value}) {
    if (_settings != null) {
      _settings!.isDarkTheme = value;
      _settings!.save();
      notifyListeners();
      print('Dark mode toggled to: $value'); // Debug log
    }
  }

  // New methods for additional settings

  void changeLanguage(String language) {
    if (_settings != null) {
      _settings!.language = language;
      _settings!.save();
      notifyListeners();
    }
  }

  void changeFontSize(double fontSize) {
    if (_settings != null) {
      _settings!.fontSize = fontSize;
      _settings!.save();
      notifyListeners();
    }
  }

  void togglePrivacy({required bool value}) {
    if (_settings != null) {
      _settings!.privacy = value;
      _settings!.save();
      notifyListeners();
    }
  }

  void changeLLMProvider(String provider) {
    if (_settings != null) {
      _settings!.selectedLLMProvider = provider;
      _settings!.save();
      notifyListeners();
    }
  }

  void toggleSentimentAnalysis({required bool value}) {
    if (_settings != null) {
      _settings!.sentimentAnalysisEnabled = value;
      _settings!.save();
      notifyListeners();
    }
  }

  void changePreferredSentimentLanguage(String language) {
    if (_settings != null) {
      _settings!.preferredSentimentLanguage = language;
      _settings!.save();
      notifyListeners();
    }
  }

  void updateLLMModelSettings(Map<String, dynamic> settings) {
    if (_settings != null) {
      _settings!.llmModelSettings = settings;
      _settings!.save();
      notifyListeners();
    }
  }

  void updateAvailableLLMProviders(List<String> providers) {
    if (_settings != null) {
      _settings!.availableLLMProviders = providers;
      _settings!.save();
      notifyListeners();
    }
  }
}
