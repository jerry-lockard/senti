import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:senti/providers/chat_provider.dart';
import 'package:senti/screens/chat_screen.dart';
import 'package:senti/screens/profile_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // list of screens
  final List<Widget> _screens = [
    const ChatScreen(),
    const ProfileScreen(), // This order matches the bottom nav items now
  ];

  @override
  void initState() {
    super.initState();

    final chatProvider = context.read<ChatProvider>();
    chatProvider.addListener(_scrollListener);

    // Optional: Initial WebSocket connection check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (chatProvider.connectionStatus != 'connected') {
        chatProvider.initializeWebSocket();
      }
    });
  }

  void _scrollListener() {
    final chatProvider = context.read<ChatProvider>();

    // Example: Check connection status
    if (chatProvider.connectionStatus == 'error') {
      // Handle WebSocket connection error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('WebSocket connection error')));
    }

    // Example: Track typing status
    if (chatProvider.isTyping) {
      // Potential UI indication of typing
      print('User is typing');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return Scaffold(
          body: PageView(
            controller: chatProvider.pageController,
            physics:
                chatProvider.navigationLocked
                    ? const NeverScrollableScrollPhysics()
                    : null,
            children: _screens,
            // Ensure that the pageController is updated correctly
          ),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor:
                Theme.of(context).colorScheme.surface, // Added for consistency
            currentIndex: chatProvider.currentIndex,
            elevation: 0,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            onTap: (index) {
              if (index == 0) {
                chatProvider.navigateToChat();
              } else if (index == 1) {
                chatProvider.navigateToProfile();
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.chat_bubble),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}
