import 'package:hive_flutter/hive_flutter.dart';

part 'user_model.g.dart';

@HiveType(typeId: 1)
class UserModel extends HiveObject {
  @HiveField(0)
  final String uid;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String image;

  @HiveField(3)
  final String? email;

  @HiveField(4)
  final DateTime createdAt;

  // New fields for sentiment and LLM preferences
  @HiveField(5)
  final String? preferredModel;

  @HiveField(6)
  final String? sentimentPreference;

  @HiveField(7)
  final Map<String, dynamic>? llmSettings;

  @HiveField(8)
  final List<String>? recentSentiments;

  // Updated constructor
  UserModel({
    required this.uid,
    required this.name,
    required this.image,
    this.email,
    DateTime? createdAt,
    this.preferredModel,
    this.sentimentPreference,
    this.llmSettings,
    this.recentSentiments,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert UserModel to Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'image': image,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
      'preferredModel': preferredModel,
      'sentimentPreference': sentimentPreference,
      'llmSettings': llmSettings,
      'recentSentiments': recentSentiments,
    };
  }

  // Create UserModel from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      image: map['image'],
      email: map['email'],
      createdAt: DateTime.parse(map['createdAt']),
      preferredModel: map['preferredModel'],
      sentimentPreference: map['sentimentPreference'],
      llmSettings: map['llmSettings'],
      recentSentiments:
          map['recentSentiments'] != null
              ? List<String>.from(map['recentSentiments'])
              : null,
    );
  }

  // Method to update user preferences
  UserModel updatePreferences({
    String? preferredModel,
    String? sentimentPreference,
    Map<String, dynamic>? llmSettings,
    List<String>? recentSentiments,
  }) {
    return UserModel(
      uid: uid,
      name: name,
      image: image,
      email: email,
      createdAt: createdAt,
      preferredModel: preferredModel ?? this.preferredModel,
      sentimentPreference: sentimentPreference ?? this.sentimentPreference,
      llmSettings: llmSettings ?? this.llmSettings,
      recentSentiments: recentSentiments ?? this.recentSentiments,
    );
  }
}
