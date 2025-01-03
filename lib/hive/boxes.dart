import 'package:senti/constants/constants.dart';
import 'package:senti/hive/chat_history.dart';
import 'package:senti/hive/settings.dart';
import 'package:senti/hive/user_model.dart';
import 'package:hive/hive.dart';

class Boxes {
  // Existing methods
  static Box<ChatHistory> getChatHistory() =>
      Hive.box<ChatHistory>(Constants.chatHistoryBox);

  static Box<UserModel> getUser() => Hive.box<UserModel>(Constants.userBox);

  static Box<Settings> getSettings() =>
      Hive.box<Settings>(Constants.settingsBox);

  // New method for WebSocket connection settings
  static Box<dynamic> getWebSocketSettings() {
    // You might want to create a specific model for WebSocket settings
    return Hive.box('websocket_settings');
  }

  // New method for LLM model preferences
  static Box<dynamic> getLLMModelPreferences() {
    // You might want to create a specific model for LLM preferences
    return Hive.box('llm_model_preferences');
  }

  // New method for sentiment analysis history
  static Box<dynamic> getSentimentHistory() {
    // You might want to create a specific model for sentiment history
    return Hive.box('sentiment_history');
  }
}

Future<void> initAllBoxes() async {
  // Existing box initializations
  await Hive.openBox<ChatHistory>(Constants.chatHistoryBox);
  await Hive.openBox<UserModel>(Constants.userBox);
  await Hive.openBox<Settings>(Constants.settingsBox);

  // New box initializations
  await Hive.openBox('websocket_settings');
  await Hive.openBox('llm_model_preferences');
  await Hive.openBox('sentiment_history');
}

// Optional: Create a method to save WebSocket connection details
Future<void> saveWebSocketConnectionDetails({
  required String url,
  required bool autoReconnect,
}) async {
  final box = Boxes.getWebSocketSettings();
  await box.put('connection_url', url);
  await box.put('auto_reconnect', autoReconnect);
}

// Optional: Create a method to save LLM model preferences
Future<void> saveLLMModelPreference({
  required String modelName,
  required Map<String, dynamic> modelConfig,
}) async {
  final box = Boxes.getLLMModelPreferences();
  await box.put(modelName, modelConfig);
}

// Optional: Create a method to save sentiment analysis history
Future<void> saveSentimentAnalysisResult({
  required String text,
  required String sentiment,
  required DateTime timestamp,
}) async {
  final box = Boxes.getSentimentHistory();
  await box.add({'text': text, 'sentiment': sentiment, 'timestamp': timestamp});
}
