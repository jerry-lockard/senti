import 'dart:developer';
import 'dart:io';
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

  // Properly define the pickImage function
  Future<void> pickImage() async {
    try {
      final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
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
      // get user data from box
      final userBox = Boxes.getUser();

      // check if user data is not empty
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
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Profile Image
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: false, // <- Changed from true to false
            backgroundColor: Theme.of(context).colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(userName),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primaryContainer,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      BuildDisplayImage(
                        file: file,
                        userImage: userImage,
                        onPressed: pickImage,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Profile Settings
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account Settings Card
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Account Settings',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.person_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text('Change Username'),
                          onTap: changeUsername,
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.lock_outline,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text('Change Password'),
                          onTap: changePassword,
                        ),
                      ],
                    ),
                  ),

                  // App Settings
                  ValueListenableBuilder<Box<Settings>>(
                    valueListenable: Boxes.getSettings().listenable(),
                    builder: (context, box, _) {
                      final settings = box.isEmpty ? null : box.getAt(0);
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'App Settings',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            SettingsTile(
                              icon: Icons.mic,
                              title: 'AI Voice',
                              value: settings?.shouldSpeak ?? false,
                              onChanged: (value) {
                                context.read<SettingsProvider>().toggleSpeak(
                                  value: value,
                                );
                              },
                              iconColor: Theme.of(context).colorScheme.primary,
                            ),
                            SettingsTile(
                              icon: Icons.notifications_outlined,
                              title: 'Notifications',
                              value: settings?.notificationsEnabled ?? false,
                              onChanged: (value) {
                                final settingsProvider =
                                    context.read<SettingsProvider>();
                                settingsProvider.toggleNotifications(
                                  value: value,
                                ); // Corrected method
                              },
                              iconColor: Theme.of(context).colorScheme.primary,
                            ),
                            SettingsTile(
                              icon: Icons.brightness_6,
                              title: 'Dark Theme',
                              value: settings?.isDarkTheme ?? false,
                              onChanged: (value) {
                                context.read<SettingsProvider>().toggleDarkMode(
                                  value: value,
                                );
                              },
                              iconColor: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  // Additional Settings Card
                  Card(
                    elevation: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Additional Settings',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.language,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text('Language'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            // Handle language settings
                          },
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.privacy_tip_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: const Text('Privacy'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: () {
                            // Handle privacy settings
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
