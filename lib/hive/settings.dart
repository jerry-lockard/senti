import 'package:hive_flutter/hive_flutter.dart';

part 'settings.g.dart';

@HiveType(typeId: 2)
class Settings extends HiveObject {
  @HiveField(0)
  bool isDarkTheme = false;

  @HiveField(1)
  bool shouldSpeak = false;

  @HiveField(2)
  String language = 'en';

  @HiveField(3)
  double fontSize = 14.0;

  @HiveField(4)
  bool notificationsEnabled = true;

  // constructor
  Settings({
    required this.isDarkTheme,
    required this.shouldSpeak,
    this.language = 'en',
    this.fontSize = 14.0,
    this.notificationsEnabled = true,
  });
}
