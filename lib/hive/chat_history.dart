import 'package:hive_flutter/hive_flutter.dart';

part 'chat_history.g.dart';

@HiveType(typeId: 0)
class ChatHistory extends HiveObject {
  @HiveField(0)
  final String chatId;

  @HiveField(1)
  final String prompt;

  @HiveField(2)
  final String response;

  @HiveField(3)
  final List<String> imagesUrls;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final String messageStatus; // e.g., sent, delivered, read

  @HiveField(6)
  final bool hasMedia; // Added field

  @HiveField(7)
  bool isFavorite; // Added field

  // New LLM and Sentiment-related fields
  @HiveField(8)
  String? usedLLMProvider; // LLM provider used for this chat

  @HiveField(9)
  String? overallConversationSentiment; // Overall sentiment of the conversation

  @HiveField(10)
  List<String>? sentimentPerMessage; // Sentiment for each message

  @HiveField(11)
  Map<String, dynamic>? llmModelConfig; // Specific LLM configuration used

  // Constructor
  ChatHistory({
    required this.chatId,
    required this.prompt,
    required this.response,
    required this.imagesUrls,
    required this.timestamp,
    this.messageStatus = 'sent',
    this.hasMedia = false,
    this.isFavorite = false,
    this.usedLLMProvider,
    this.overallConversationSentiment,
    this.sentimentPerMessage,
    this.llmModelConfig,
  });

  // toMap
  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'prompt': prompt,
      'response': response,
      'imagesUrls': imagesUrls,
      'timestamp': timestamp.toIso8601String(),
      'hasMedia': hasMedia,
      'isFavorite': isFavorite,
      'usedLLMProvider': usedLLMProvider,
      'overallConversationSentiment': overallConversationSentiment,
      'sentimentPerMessage': sentimentPerMessage,
      'llmModelConfig': llmModelConfig,
    };
  }

  // from map
  factory ChatHistory.fromMap(Map<String, dynamic> map) {
    return ChatHistory(
      chatId: map['chatId'],
      prompt: map['prompt'],
      response: map['response'],
      imagesUrls: List<String>.from(map['imagesUrls']),
      timestamp: DateTime.parse(map['timestamp']),
      hasMedia: map['hasMedia'] ?? false,
      isFavorite: map['isFavorite'] ?? false,
      usedLLMProvider: map['usedLLMProvider'],
      overallConversationSentiment: map['overallConversationSentiment'],
      sentimentPerMessage:
          map['sentimentPerMessage'] != null
              ? List<String>.from(map['sentimentPerMessage'])
              : null,
      llmModelConfig: map['llmModelConfig'],
    );
  }

  // copyWith
  ChatHistory copyWith({
    String? chatId,
    String? prompt,
    String? response,
    List<String>? imagesUrls,
    DateTime? timestamp,
    String? messageStatus,
    bool? hasMedia,
    bool? isFavorite,
    String? usedLLMProvider,
    String? overallConversationSentiment,
    List<String>? sentimentPerMessage,
    Map<String, dynamic>? llmModelConfig,
  }) {
    return ChatHistory(
      chatId: chatId ?? this.chatId,
      prompt: prompt ?? this.prompt,
      response: response ?? this.response,
      imagesUrls: imagesUrls ?? this.imagesUrls,
      timestamp: timestamp ?? this.timestamp,
      messageStatus: messageStatus ?? this.messageStatus,
      hasMedia: hasMedia ?? this.hasMedia,
      isFavorite: isFavorite ?? this.isFavorite,
      usedLLMProvider: usedLLMProvider ?? this.usedLLMProvider,
      overallConversationSentiment:
          overallConversationSentiment ?? this.overallConversationSentiment,
      sentimentPerMessage: sentimentPerMessage ?? this.sentimentPerMessage,
      llmModelConfig: llmModelConfig ?? this.llmModelConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatHistory && other.chatId == chatId;
  }

  @override
  int get hashCode {
    return chatId.hashCode;
  }
}
