import 'package:flutter/material.dart';
import 'package:senti/hive/boxes.dart';
import 'package:senti/hive/chat_history.dart';
import 'package:senti/widgets/chat_history_widget.dart';
import 'package:senti/widgets/empty_history_widget.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
        title: const Text('Chat history'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search chat history...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
              ),
              onChanged: (query) {
                // Implement search logic here
              },
            ),
          ),
        ),
      ),
      body: ValueListenableBuilder<Box<ChatHistory>>(
        valueListenable: Boxes.getChatHistory().listenable(),
        builder: (context, box, _) {
          final chatHistory =
              box.values.toList().cast<ChatHistory>().reversed.toList();
          return chatHistory.isEmpty
              ? const EmptyHistoryWidget()
              : Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  itemCount: chatHistory.length,
                  itemBuilder: (context, index) {
                    final chat = chatHistory[index];
                    return Dismissible(
                      key: Key(chat.key.toString()),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        // Implement delete individual chat history logic here
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(Icons.delete, color: Colors.white),
                      ),
                      child: ListTile(
                        title: ChatHistoryWidget(chat: chat),
                        trailing: IconButton(
                          icon: Icon(
                            chat.isFavorite ? Icons.star : Icons.star_border,
                            color: chat.isFavorite ? Colors.yellow : null,
                          ),
                          onPressed: () {
                            // Implement mark as favorite logic here
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
        },
      ),
    );
  }
}
