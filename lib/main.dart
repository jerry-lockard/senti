import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:senti/hive/boxes.dart';
import 'package:senti/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:senti/providers/chat_provider.dart';
import 'package:senti/providers/settings_provider.dart';
import 'package:senti/providers/websocket_provider.dart'; // New provider
import 'package:senti/providers/sentiment_provider.dart'; // New provider
import 'package:senti/providers/llm_provider.dart'; // New provider
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await ChatProvider.initHive();
  await initAllBoxes();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ChatProvider()),
        ChangeNotifierProvider(create: (context) => SettingsProvider()),
        ChangeNotifierProvider(create: (context) => WebSocketProvider()),
        ChangeNotifierProvider(create: (context) => SentimentProvider()),
        ChangeNotifierProvider(create: (context) => LLMProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settingsProvider, child) {
        return MaterialApp(
          title: 'Senti ✨',
          theme:
              settingsProvider.settings?.isDarkTheme ?? false
                  ? ThemeData.dark()
                  : ThemeData.light(),
          home: const HomeScreen(),
        );
      },
    );
  }
}
