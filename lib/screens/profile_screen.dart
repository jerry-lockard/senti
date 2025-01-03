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

  // Existing methods remain the same...
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

  void getUserData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userBox = Boxes.getUser();
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

  // New method to show LLM model configuration dialog
  void _showLLMConfigDialog(Settings currentSettings) {
    showDialog(
      context: context,
      builder: (context) {
        Map<String, dynamic> modelConfig =
            currentSettings.llmModelSettings ?? {};

        TextEditingController temperatureController = TextEditingController(
          text: (modelConfig['temperature'] ?? 0.7).toString(),
        );
        TextEditingController maxTokensController = TextEditingController(
          text: (modelConfig['max_tokens'] ?? 150).toString(),
        );

        return AlertDialog(
          title: Text('LLM Model Configuration'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: temperatureController,
                decoration: InputDecoration(
                  labelText: 'Temperature',
                  hintText: 'Creativity level (0.0 - 1.0)',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              TextField(
                controller: maxTokensController,
                decoration: InputDecoration(
                  labelText: 'Max Tokens',
                  hintText: 'Maximum response length',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final settingsBox = Boxes.getSettings();
                final newConfig = {
                  'temperature':
                      double.tryParse(temperatureController.text) ?? 0.7,
                  'max_tokens': int.tryParse(maxTokensController.text) ?? 150,
                };

                settingsBox.putAt(
                  0,
                  currentSettings.updateLLMModelSettings(newConfig),
                );
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
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: false,
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
                                );
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

                  // LLM and AI Settings Card
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
                                'AI and Language Model Settings',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),

                            // LLM Provider Selection
                            ListTile(
                              leading: Icon(
                                Icons.model_training,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              title: const Text('Language Model Provider'),
                              trailing: DropdownButton<String>(
                                value:
                                    settings?.selectedLLMProvider ?? 'gemini',
                                items:
                                    settings?.availableLLMProviders.map((
                                      String model,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: model,
                                        child: Text(model),
                                      );
                                    }).toList() ??
                                    [],
                                onChanged: (String? newModel) {
                                  if (newModel != null && settings != null) {
                                    final settingsBox = Boxes.getSettings();
                                    settingsBox.putAt(
                                      0,
                                      settings.updateLLMProvider(newModel),
                                    );
                                  }
                                },
                              ),
                            ),

                            // LLM Model Configuration
                            ListTile(
                              leading: Icon(
                                Icons.settings,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              title: const Text('Model Configuration'),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onTap: () => _showLLMConfigDialog(settings!),
                            ),

                            // Sentiment Analysis Toggle
                            SwitchListTile(
                              title: const Text('Sentiment Analysis'),
                              subtitle: const Text(
                                'Enable emotional context detection',
                              ),
                              value: settings?.sentimentAnalysisEnabled ?? true,
                              onChanged: (bool value) {
                                if (settings != null) {
                                  final settingsBox = Boxes.getSettings();
                                  settingsBox.putAt(
                                    0,
                                    settings.toggleSentimentAnalysis(value),
                                  );
                                }
                              },
                              secondary: Icon(
                                Icons.sentiment_satisfied_alt,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),

                            // Sentiment Language Selection
                            ListTile(
                              leading: Icon(
                                Icons.language,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              title: const Text('Sentiment Analysis Language'),
                              trailing: DropdownButton<String>(
                                value:
                                    settings?.preferredSentimentLanguage ??
                                    'en',
                                items:
                                    ['en', 'es', 'fr', 'de', 'zh'].map((
                                      String language,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: language,
                                        child: Text(language.toUpperCase()),
                                      );
                                    }).toList(),
                                onChanged: (String? newLanguage) {
                                  if (newLanguage != null && settings != null) {
                                    final settingsBox = Boxes.getSettings();
                                    settingsBox.putAt(
                                      0,
                                      settings.copyWith(
                                        preferredSentimentLanguage: newLanguage,
                                      ),
                                    );
                                  }
                                },
                              ),
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
