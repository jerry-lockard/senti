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

  @HiveField(5)
  bool privacy = true; // Added privacy field

  // New LLM and Sentiment-related fields
  @HiveField(6)
  String selectedLLMProvider = 'gemini'; // Default LLM provider

  @HiveField(7)
  bool sentimentAnalysisEnabled = true; // Toggle sentiment analysis

  @HiveField(8)
  String preferredSentimentLanguage = 'en'; // Sentiment analysis language

  @HiveField(9)
  Map<String, dynamic>? llmModelSettings; // Custom LLM model configurations

  @HiveField(10)
  List<String> availableLLMProviders = ['gemini', 'openai', 'ollama', 'llama']; // List of available LLM providers

  // Constructor
  Settings({
    this.isDarkTheme = false,
    this.shouldSpeak = false,
    this.language = 'en',
    this.fontSize = 14.0,
    this.notificationsEnabled = true,
    this.privacy = true,
    this.selectedLLMProvider = 'gemini',
    this.sentimentAnalysisEnabled = true,
    this.preferredSentimentLanguage = 'en',
    this.llmModelSettings,
    List<String>? availableLLMProviders,
  }) {
    if (availableLLMProviders != null) {
      this.availableLLMProviders = availableLLMProviders;
    }
  }

  Settings copyWith({
    bool? isDarkTheme,
    bool? shouldSpeak,
    String? language,
    double? fontSize,
    bool? notificationsEnabled,
    bool? privacy,
    String? selectedLLMProvider,
    bool? sentimentAnalysisEnabled,
    String? preferredSentimentLanguage,
    Map<String, dynamic>? llmModelSettings,
    List<String>? availableLLMProviders,
  }) {
    return Settings(
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
      shouldSpeak: shouldSpeak ?? this.shouldSpeak,
      language: language ?? this.language,
      fontSize: fontSize ?? this.fontSize,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      privacy: privacy ?? this.privacy,
      selectedLLMProvider: selectedLLMProvider ?? this.selectedLLMProvider,
      sentimentAnalysisEnabled:
          sentimentAnalysisEnabled ?? this.sentimentAnalysisEnabled,
      preferredSentimentLanguage:
          preferredSentimentLanguage ?? this.preferredSentimentLanguage,
      llmModelSettings: llmModelSettings ?? this.llmModelSettings,
      availableLLMProviders:
          availableLLMProviders ?? this.availableLLMProviders,
    );
  }

  // Method to update LLM provider
  Settings updateLLMProvider(String provider) {
    return Settings(
      isDarkTheme: isDarkTheme,
      shouldSpeak: shouldSpeak,
      language: language,
      fontSize: fontSize,
      notificationsEnabled: notificationsEnabled,
      privacy: privacy,
      selectedLLMProvider: provider,
      sentimentAnalysisEnabled: sentimentAnalysisEnabled,
      preferredSentimentLanguage: preferredSentimentLanguage,
      llmModelSettings: llmModelSettings,
      availableLLMProviders: availableLLMProviders,
    );
  }

  // Method to toggle sentiment analysis
  Settings toggleSentimentAnalysis(bool enabled) {
    return Settings(
      isDarkTheme: isDarkTheme,
      shouldSpeak: shouldSpeak,
      language: language,
      fontSize: fontSize,
      notificationsEnabled: notificationsEnabled,
      privacy: privacy,
      selectedLLMProvider: selectedLLMProvider,
      sentimentAnalysisEnabled: enabled,
      preferredSentimentLanguage: preferredSentimentLanguage,
      llmModelSettings: llmModelSettings,
      availableLLMProviders: availableLLMProviders,
    );
  }

  // Method to update LLM model settings
  Settings updateLLMModelSettings(Map<String, dynamic> settings) {
    return Settings(
      isDarkTheme: isDarkTheme,
      shouldSpeak: shouldSpeak,
      language: language,
      fontSize: fontSize,
      notificationsEnabled: notificationsEnabled,
      privacy: privacy,
      selectedLLMProvider: selectedLLMProvider,
      sentimentAnalysisEnabled: sentimentAnalysisEnabled,
      preferredSentimentLanguage: preferredSentimentLanguage,
      llmModelSettings: settings,
      availableLLMProviders: availableLLMProviders,
    );
  }
}
