// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatHistoryAdapter extends TypeAdapter<ChatHistory> {
  @override
  final int typeId = 0;

  @override
  ChatHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatHistory(
      chatId: fields[0] as String,
      prompt: fields[1] as String,
      response: fields[2] as String,
      imagesUrls: (fields[3] as List).cast<String>(),
      timestamp: fields[4] as DateTime,
      messageStatus: fields[5] as String,
      hasMedia: fields[6] as bool,
      isFavorite: fields[7] as bool,
      usedLLMProvider: fields[8] as String?,
      overallConversationSentiment: fields[9] as String?,
      sentimentPerMessage: (fields[10] as List?)?.cast<String>(),
      llmModelConfig: (fields[11] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ChatHistory obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.chatId)
      ..writeByte(1)
      ..write(obj.prompt)
      ..writeByte(2)
      ..write(obj.response)
      ..writeByte(3)
      ..write(obj.imagesUrls)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.messageStatus)
      ..writeByte(6)
      ..write(obj.hasMedia)
      ..writeByte(7)
      ..write(obj.isFavorite)
      ..writeByte(8)
      ..write(obj.usedLLMProvider)
      ..writeByte(9)
      ..write(obj.overallConversationSentiment)
      ..writeByte(10)
      ..write(obj.sentimentPerMessage)
      ..writeByte(11)
      ..write(obj.llmModelConfig);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
