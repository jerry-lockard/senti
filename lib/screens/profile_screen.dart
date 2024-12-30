import 'dart:developer';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:senti/hive/boxes.dart';
import 'package:senti/hive/settings.dart';
import 'package:senti/providers/settings_provider.dart';
import 'package:senti/widgets/build_display_image.dart';
import 'package:senti/widgets/settings_tile.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? file;
  String userImage = '';
  String userName = 'Senti';
  final ImagePicker _picker = ImagePicker();

  // pick an image
  void pickImage() async {
    try {
      final pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        maxHeight: 800,
        maxWidth: 800,
        imageQuality: 95,
      );
      if (pickedImage != null) {
        setState(() {
          file = File(pickedImage.path);
        });
      }
    } catch (e) {
      log('error : $e');
    }
  }

  // get user data
  void getUserData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // get user data fro box
      final userBox = Boxes.getUser();

      // check is user data is not empty
      if (userBox.isNotEmpty) {
        final user = userBox.getAt(0);
        setState(() {
          userImage = user!.name;
          userName = user.image;
        });
      }
    });
  }

  @override
  void initState() {
    getUserData();
    super.initState();
  }

  // Change username
  void changeUsername() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController controller = TextEditingController(
          text: userName,
        );
        return AlertDialog(
          title: Text('Change Username'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "Enter new username"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  userName = controller.text;
                });
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Change password
  void changePassword() {
    showDialog(
      context: context,
      builder: (context) {
        TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: Text('Change Password'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: "Enter new password"),
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Handle password change logic here
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.checkmark),
            color: Theme.of(context).colorScheme.onPrimary,
            onPressed: () {
              // save data
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: BuildDisplayImage(
                  file: file,
                  userImage: userImage,
                  onPressed: () {
                    // open camera or gallery
                    pickImage();
                  },
                ),
              ),
              const SizedBox(height: 20.0),

              // user name
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(userName, style: Theme.of(context).textTheme.titleLarge),
                  IconButton(
                    icon: Icon(Icons.pin_end_rounded),
                    onPressed: changeUsername,
                  ),
                ],
              ),

              const SizedBox(height: 20.0),

              // Change password
              ElevatedButton(
                onPressed: changePassword,
                child: Text('Change Password'),
              ),

              const SizedBox(height: 20.0),

              ValueListenableBuilder<Box<Settings>>(
                valueListenable: Boxes.getSettings().listenable(),
                builder: (context, box, child) {
                  if (box.isEmpty) {
                    return Column(
                      children: [
                        // ai voice
                        SettingsTile(
                          icon: Icons.mic,
                          title: 'Enable AI voice',
                          value: false,
                          onChanged: (value) {
                            final settingProvider =
                                context.read<SettingsProvider>();
                            settingProvider.toggleSpeak(value: value);
                          },
                          iconColor: Theme.of(context).colorScheme.primary,
                        ),

                        const SizedBox(height: 10.0),

                        // Theme
                        SettingsTile(
                          icon: Icons.sunny,
                          title: 'Theme',
                          value: false,
                          onChanged: (value) {
                            final settingProvider =
                                context.read<SettingsProvider>();
                            settingProvider.toggleDarkMode(value: value);
                          },
                          iconColor: Theme.of(context).colorScheme.primary,
                        ),

                        const SizedBox(height: 10.0),

                        // Notifications
                        SettingsTile(
                          icon: Icons.notifications,
                          title: 'Enable Notifications',
                          value: false,
                          onChanged: (value) {
                            final settingProvider =
                                context.read<SettingsProvider>();
                            settingProvider.toggleNotifications(value: value);
                          },
                        ),

                        const SizedBox(height: 10.0),

                        // Language
                        SettingsTile(
                          icon: Icons.settings,
                          title: 'Language',
                          value: false,
                          onChanged: (value) {
                            // Handle language change logic here
                          },
                        ),

                        const SizedBox(height: 10.0),

                        // Privacy
                        SettingsTile(
                          icon: Icons.lock,
                          title: 'Privacy Settings',
                          value: false,
                          onChanged: (value) {
                            // Handle privacy settings logic here
                          },
                        ),
                      ],
                    );
                  } else {
                    final settings = box.getAt(0);
                    return Column(
                      children: [
                        // ai voice
                        SettingsTile(
                          icon: Icons.mic,
                          title: 'Enable AI voice',
                          value: settings!.shouldSpeak,
                          onChanged: (value) {
                            final settingProvider =
                                context.read<SettingsProvider>();
                            settingProvider.toggleSpeak(value: value);
                          },
                          iconColor: Theme.of(context).colorScheme.primary,
                        ),

                        const SizedBox(height: 10.0),

                        // theme
                        SettingsTile(
                          icon:
                              settings.isDarkTheme
                                  ? Icons.dark_mode
                                  : Icons.sunny,
                          title: 'Theme',
                          value: settings.isDarkTheme,
                          onChanged: (value) {
                            final settingProvider =
                                context.read<SettingsProvider>();
                            settingProvider.toggleDarkMode(value: value);
                          },
                          iconColor: Theme.of(context).colorScheme.primary,
                        ),

                        const SizedBox(height: 10.0),

                        // Notifications
                        SettingsTile(
                          icon: CupertinoIcons.bell,
                          title: 'Enable Notifications',
                          value: settings.notificationsEnabled,
                          onChanged: (value) {
                            final settingProvider =
                                context.read<SettingsProvider>();
                            settingProvider.toggleNotifications(value: value);
                          },
                        ),

                        const SizedBox(height: 10.0),

                        // Language
                        SettingsTile(
                          icon: Icons.language,
                          title: 'Language',
                          value: false, // or any appropriate boolean value
                          onChanged: (value) {
                            // Handle language change logic here
                          },
                        ),

                        const SizedBox(height: 10.0),

                        // Privacy
                        SettingsTile(
                          icon: Icons.lock,
                          title: 'Privacy Settings',
                          value: settings.privacy,
                          onChanged: (value) {
                            // Handle privacy settings logic here
                          },
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
