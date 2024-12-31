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
    // Initialize listener here instead of in build
    final chatProvider = context.read<ChatProvider>();
    chatProvider.addListener(_scrollListener);
  }

  void _scrollListener() {
    // Implement your scroll logic here
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
