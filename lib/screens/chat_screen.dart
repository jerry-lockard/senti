import 'package:flutter/material.dart';
import 'package:senti/providers/chat_provider.dart';
import 'package:senti/widgets/bottom_chat_field.dart';
import 'package:senti/widgets/chat_messages.dart';
import 'package:provider/provider.dart';
import 'package:senti/screens/chat_history_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // scroll controller
  final ScrollController _scrollController = ScrollController();
  late ChatProvider _chatProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Obtain the ChatProvider reference without listening
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _chatProvider.addListener(_scrollListener);
  }

  @override
  void dispose() {
    // Use the stored ChatProvider reference
    _chatProvider.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_chatProvider.inChatMessages.isNotEmpty) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients &&
          _scrollController.position.maxScrollExtent > 0.0) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.inChatMessages.isNotEmpty) {
          _scrollToBottom();
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            centerTitle: true,
            title: const Text('Chat with Senti'),
            actions: [
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    isDismissible: true,
                    useSafeArea: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder:
                        (BuildContext context) => FractionallySizedBox(
                          heightFactor: 0.9,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 4,
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const Text(
                                  'Chat History',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Divider(),
                                const Expanded(child: ChatHistoryScreen()),
                              ],
                            ),
                          ),
                        ),
                  );
                },
              ),
              // Increased touch target size for the '+' button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Container(
                  // Added Container to enlarge touch area
                  width: 48, // Increased width
                  height: 48, // Increased height
                  child: IconButton(
                    icon: const Icon(Icons.add),
                    iconSize: 30, // Increased icon size
                    padding: EdgeInsets.zero, // Removed default padding
                    constraints: const BoxConstraints(), // Removed constraints
                    onPressed: () async {
                      try {
                        await chatProvider.prepareChatRoom(isNewChat: true);
                        chatProvider.navigateToChat();
                        // Optionally, reset any UI elements if needed
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to create new chat: $e'),
                          ),
                        );
                      }
                    },
                  ),
                  // Optional: Add a border for debugging touch area
                  // decoration: BoxDecoration(
                  //   border: Border.all(color: Colors.red),
                  //   shape: BoxShape.circle,
                  // ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Expanded(
                    child:
                        chatProvider.inChatMessages.isEmpty
                            ? const Center(child: Text('No messages yet'))
                            : ChatMessages(
                              scrollController: _scrollController,
                              chatProvider: chatProvider,
                            ),
                  ),

                  BottomChatField(chatProvider: chatProvider),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
