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
  }

  void toggleSpeak({required bool value}) {
    if (_settings != null) {
      _settings!.shouldSpeak = value;
      _settings!.save();
      notifyListeners();
    }
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
}
