import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:senti/providers/chat_provider.dart';
import 'package:senti/providers/websocket_provider.dart';
import 'package:senti/widgets/bottom_chat_field.dart';
import 'package:senti/widgets/chat_messages.dart';
import 'package:senti/screens/chat_history_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  late ChatProvider _chatProvider;
  late WebSocketProvider _webSocketProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _webSocketProvider = Provider.of<WebSocketProvider>(context, listen: false);
    _webSocketProvider.addListener(_scrollListener);
    _chatProvider.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _webSocketProvider.removeListener(_scrollListener);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: Duration.zero,
        curve: Curves.linear,
      );
    }
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
    return Consumer2<ChatProvider, WebSocketProvider>(
      builder: (context, chatProvider, webSocketProvider, child) {
        if (chatProvider.inChatMessages.isNotEmpty) {
          _scrollToBottom();
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            centerTitle: true,
            title: const Text('Chat with Senti'),
            actions: [
              DropdownButton<String>(
                value: webSocketProvider.selectedModel,
                items:
                    webSocketProvider.availableModels.map((model) {
                      return DropdownMenuItem(
                        value: model,
                        child: Text(model.toUpperCase()),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    webSocketProvider.changeModel(value);
                  }
                },
              ),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Container(
                  width: 48,
                  height: 48,
                  child: IconButton(
                    icon: const Icon(Icons.add),
                    iconSize: 30,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      try {
                        await chatProvider.prepareChatRoom(isNewChat: true);
                        chatProvider.navigateToChat();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to create new chat: $e'),
                          ),
                        );
                      }
                    },
                  ),
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
                  BottomChatField(
                    chatProvider: chatProvider,
                    onSendMessage: (message) {
                      webSocketProvider.sendMessage(message);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
