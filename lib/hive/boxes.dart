import 'package:senti/constants/constants.dart';
import 'package:senti/hive/chat_history.dart';
import 'package:senti/hive/settings.dart';
import 'package:senti/hive/user_model.dart';
import 'package:hive/hive.dart';

class Boxes {
  // get the chat history box
  static Box<ChatHistory> getChatHistory() =>
      Hive.box<ChatHistory>(Constants.chatHistoryBox);

  // get user box
  static Box<UserModel> getUser() => Hive.box<UserModel>(Constants.userBox);

  // get settings box
  static Box<Settings> getSettings() =>
      Hive.box<Settings>(Constants.settingsBox);
}

Future<void> initAllBoxes() async {
  await Hive.openBox<ChatHistory>(Constants.chatHistoryBox);
  await Hive.openBox<UserModel>(Constants.userBox);
  await Hive.openBox<Settings>(Constants.settingsBox);
}
