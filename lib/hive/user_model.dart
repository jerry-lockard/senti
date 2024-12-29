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

  // constructor
  UserModel({
    required this.uid,
    required this.name,
    required this.image,
    this.email,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert UserModel to Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'image': image,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
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
    );
  }
}
