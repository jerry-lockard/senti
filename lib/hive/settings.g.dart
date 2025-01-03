// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsAdapter extends TypeAdapter<Settings> {
  @override
  final int typeId = 2;

  @override
  Settings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Settings(
      isDarkTheme: fields[0] as bool,
      shouldSpeak: fields[1] as bool,
      language: fields[2] as String,
      fontSize: fields[3] as double,
      notificationsEnabled: fields[4] as bool,
      privacy: fields[5] as bool,
      selectedLLMProvider: fields[6] as String,
      sentimentAnalysisEnabled: fields[7] as bool,
      preferredSentimentLanguage: fields[8] as String,
      llmModelSettings: (fields[9] as Map?)?.cast<String, dynamic>(),
      availableLLMProviders: (fields[10] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, Settings obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.isDarkTheme)
      ..writeByte(1)
      ..write(obj.shouldSpeak)
      ..writeByte(2)
      ..write(obj.language)
      ..writeByte(3)
      ..write(obj.fontSize)
      ..writeByte(4)
      ..write(obj.notificationsEnabled)
      ..writeByte(5)
      ..write(obj.privacy)
      ..writeByte(6)
      ..write(obj.selectedLLMProvider)
      ..writeByte(7)
      ..write(obj.sentimentAnalysisEnabled)
      ..writeByte(8)
      ..write(obj.preferredSentimentLanguage)
      ..writeByte(9)
      ..write(obj.llmModelSettings)
      ..writeByte(10)
      ..write(obj.availableLLMProviders);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
