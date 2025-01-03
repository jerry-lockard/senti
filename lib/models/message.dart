import 'package:hive/hive.dart';

part 'message.g.dart';

@HiveType(typeId: 0)
class Message {
  @HiveField(0)
  String messageId;

  @HiveField(1)
  String chatId;

  @HiveField(2)
  Role role;

  @HiveField(3)
  StringBuffer message;

  @HiveField(4)
  List<String> imagesUrls;

  @HiveField(5)
  DateTime timeSent;

  @HiveField(6)
  bool isRead; // Added field

  @HiveField(7)
  String? sentiment; // Optional sentiment field

  // constructor
  // Update constructor
  Message({
    required this.messageId,
    required this.chatId,
    required this.role,
    required this.message,
    required this.imagesUrls,
    required this.timeSent,
    this.isRead = false,
    this.sentiment, // New optional parameter
  });

  // Update toMap method
  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'chatId': chatId,
      'role': role.index,
      'message': message.toString(),
      'imagesUrls': imagesUrls,
      'timeSent': timeSent.toIso8601String(),
      'isRead': isRead,
      'sentiment': sentiment, // Add sentiment
    };
  }

  // Update fromMap method
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      messageId: map['messageId'],
      chatId: map['chatId'],
      role: Role.values[map['role']],
      message: StringBuffer(map['message']),
      imagesUrls: List<String>.from(map['imagesUrls']),
      timeSent: DateTime.parse(map['timeSent']),
      isRead: map['isRead'] ?? false,
      sentiment: map['sentiment'], // Add sentiment
    );
  }

  // Update copyWith method
  Message copyWith({
    String? messageId,
    String? chatId,
    Role? role,
    StringBuffer? message,
    List<String>? imagesUrls,
    DateTime? timeSent,
    bool? isRead,
    String? sentiment, // Add sentiment
  }) {
    return Message(
      messageId: messageId ?? this.messageId,
      chatId: chatId ?? this.chatId,
      role: role ?? this.role,
      message: message ?? this.message,
      imagesUrls: imagesUrls ?? this.imagesUrls,
      timeSent: timeSent ?? this.timeSent,
      isRead: isRead ?? this.isRead,
      sentiment: sentiment ?? this.sentiment, // Add sentiment
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Message && other.messageId == messageId;
  }

  @override
  int get hashCode {
    return messageId.hashCode;
  }
}

enum Role { user, assistant, admin, system, ai, human }
