import 'package:flutter/material.dart';
import 'package:senti/hive/boxes.dart';
import 'package:senti/hive/chat_history.dart';
import 'package:senti/widgets/chat_history_widget.dart';
import 'package:senti/widgets/empty_history_widget.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:senti/providers/chat_provider.dart';

class ChatHistoryScreen extends StatelessWidget {
  const ChatHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<ChatHistory>>(
      valueListenable: Boxes.getChatHistory().listenable(),
      builder: (context, box, _) {
        final chatHistory =
            box.values.toList().cast<ChatHistory>().reversed.toList();
        return chatHistory.isEmpty
            ? const EmptyHistoryWidget()
            : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemCount: chatHistory.length,
              itemBuilder: (context, index) {
                final chat = chatHistory[index];
                return Dismissible(
                  key: Key(chat.key.toString()),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    // Delete chat history item
                    box.delete(chat.key);
                  },
                  background: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                    ),
                  ),
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      title: ChatHistoryWidget(chat: chat),
                      trailing: IconButton(
                        icon: Icon(
                          chat.isFavorite ? Icons.star : Icons.star_border,
                          color: chat.isFavorite ? Colors.amber : null,
                        ),
                        onPressed: () {
                          chat.isFavorite = !chat.isFavorite;
                          chat.save();
                        },
                      ),
                      onTap: () async {
                        // Get provider without context
                        final chatProvider = context.read<ChatProvider>();

                        // Load chat data
                        await chatProvider.prepareChatRoom(
                          isNewChat: false,
                          chatID: chat.chatId,
                        );

                        // Dismiss the bottom sheet first
                        Navigator.pop(context);

                        // Force to chat screen after dismissal
                        chatProvider.forceToChat();
                      },
                    ),
                  ),
                );
              },
            );
      },
    );
  }
}
