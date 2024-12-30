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
  final bool isFavorite; // Added field

  // constructor
  ChatHistory({
    required this.chatId,
    required this.prompt,
    required this.response,
    required this.imagesUrls,
    required this.timestamp,
    this.messageStatus = 'sent',
    this.hasMedia = false, // Default value
    this.isFavorite = false, // Default value
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
      hasMedia: map['hasMedia'] ?? false, // Handle JSON
      isFavorite: map['isFavorite'] ?? false, // Handle JSON
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
