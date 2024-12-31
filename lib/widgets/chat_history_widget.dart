import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:senti/hive/chat_history.dart';
import 'package:senti/providers/chat_provider.dart';
import 'package:senti/utility/animated_dialog.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting

class ChatHistoryWidget extends StatelessWidget {
  const ChatHistoryWidget({super.key, required this.chat});

  final ChatHistory chat;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 10.0, right: 10.0),
        leading: Stack(
          children: [
            const CircleAvatar(
              radius: 30,
              child: Icon(CupertinoIcons.chat_bubble_2),
            ),
            if (chat.hasMedia)
              Positioned(
                bottom: 0,
                right: 0,
                child: Icon(Icons.image, color: Colors.green, size: 20),
              ),
          ],
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(chat.prompt, maxLines: 1),
            if (chat.isFavorite) Icon(Icons.star, color: Colors.yellow),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(chat.response, maxLines: 2),
            Text(
              DateFormat('hh:mm a, MMM d, yyyy').format(chat.timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () async {
          // navigate to chat screen
          final chatProvider = context.read<ChatProvider>();
          // prepare chat room
          await chatProvider.prepareChatRoom(
            isNewChat: false,
            chatID: chat.chatId,
          );
          chatProvider.navigateToChat();
        },
        onLongPress: () {
          // show my animated dialog to delete the chat
          showMyAnimatedDialog(
            context: context,
            title: 'Delete Chat',
            content: 'Are you sure you want to delete this chat?',
            actionText: 'Delete',
            onActionPressed: (value) async {
              if (value) {
                // delete the chat
                await context.read<ChatProvider>().deleteChatMessages(
                  chatId: chat.chatId,
                );

                // delete the chat history
                await chat.delete();
              }
            },
          );
        },
      ),
    );
  }
}
