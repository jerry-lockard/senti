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
            showModalBottomSheet(
              context: context,
              builder: (context) {
                return Wrap(
                  children: [
                    // Sentiment Analysis Indicator
                    ListTile(
                      leading: Icon(
                        _getSentimentIcon(chatProvider.lastSentiment),
                        color: _getSentimentColor(chatProvider.lastSentiment),
                      ),
                      title: Text('Sentiment: ${chatProvider.lastSentiment}'),
                    ),

                    // Model Selection
                    ListTile(
                      leading: Icon(Icons.model_training),
                      title: Text(
                        'Current Model: ${chatProvider.selectedModel}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (String model) {
                          chatProvider.changeModel(model);
                          Navigator.pop(context);
                        },
                        itemBuilder: (BuildContext context) {
                          return chatProvider.availableModels.map((
                            String model,
                          ) {
                            return PopupMenuItem<String>(
                              value: model,
                              child: Text(model),
                            );
                          }).toList();
                        },
                      ),
                    ),

                    // Existing Reaction Options
                    ListTile(
                      leading: Icon(Icons.thumb_up),
                      title: Text('Like'),
                      onTap: () {
                        // Analyze sentiment of the message
                        chatProvider.analyzeSentiment(
                          message.message.toString(),
                        );
                        Navigator.pop(context);
                      },
                    ),

                    ListTile(
                      leading: Icon(Icons.thumb_down),
                      title: Text('Dislike'),
                      onTap: () {
                        // Analyze sentiment of the message
                        chatProvider.analyzeSentiment(
                          message.message.toString(),
                        );
                        Navigator.pop(context);
                      },
                    ),
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
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child:
                    message.role.name == Role.user.name
                        ? MyMessageWidget(message: message)
                        : AssistantMessageWidget(
                          message: message.message.toString(),
                        ),
              ),
              // Optional: Connection Status Indicator
              if (chatProvider.connectionStatus != 'connected')
                Text(
                  'Connection Status: ${chatProvider.connectionStatus}',
                  style: TextStyle(
                    color:
                        chatProvider.connectionStatus == 'error'
                            ? Colors.red
                            : Colors.orange,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // Helper methods for sentiment and icon display
  IconData _getSentimentIcon(String sentiment) {
    switch (sentiment) {
      case 'positive':
        return Icons.sentiment_very_satisfied;
      case 'negative':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment) {
      case 'positive':
        return Colors.green;
      case 'negative':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
