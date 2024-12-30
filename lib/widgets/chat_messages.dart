import 'package:flutter/material.dart';
import 'package:senti/models/message.dart';
import 'package:senti/providers/chat_provider.dart';
import 'package:senti/widgets/assistant_message_widget.dart';
import 'package:senti/widgets/my_message_widget.dart';

class ChatMessages extends StatelessWidget {
  const ChatMessages({
    super.key,
    required this.scrollController,
    required this.chatProvider,
  });

  final ScrollController scrollController;
  final ChatProvider chatProvider;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      itemCount: chatProvider.inChatMessages.length,
      itemBuilder: (context, index) {
        final message = chatProvider.inChatMessages[index];
        return GestureDetector(
          onLongPress: () {
            // Show a dialog or bottom sheet with reaction options
            showModalBottomSheet(
              context: context,
              builder: (context) {
                return Wrap(
                  children: [
                    ListTile(
                      leading: Icon(Icons.thumb_up),
                      title: Text('Like'),
                      onTap: () {
                        // Handle reaction
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.thumb_down),
                      title: Text('Dislike'),
                      onTap: () {
                        // Handle reaction
                        Navigator.pop(context);
                      },
                    ),
                    // Add more reactions as needed
                  ],
                );
              },
            );
          },
          child: Column(
            crossAxisAlignment:
                message.role.name == Role.user.name
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(
                  vertical: 2.0,
                  horizontal: 8.0,
                ),
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.transparent, // Removed background color
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child:
                    message.role.name == Role.user.name
                        ? MyMessageWidget(message: message)
                        : AssistantMessageWidget(
                          message: message.message.toString(),
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}
