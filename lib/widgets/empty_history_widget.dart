import 'package:flutter/material.dart';
import 'package:senti/providers/chat_provider.dart';
import 'package:provider/provider.dart';

class EmptyHistoryWidget extends StatelessWidget {
  const EmptyHistoryWidget({
    super.key,
    this.message = 'No chat found, start a new chat!',
    this.icon = Icons.chat_bubble_outline,
    this.backgroundImage,
  });

  final String message;
  final IconData icon;
  final String? backgroundImage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (backgroundImage != null)
              Image.asset(
                backgroundImage!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 50,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 10),
                    Text(message),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        final chatProvider = context.read<ChatProvider>();
                        chatProvider.prepareChatRoom(
                          isNewChat: true,
                          chatID: '',
                        );
                      },
                      child: const Text('Start New Chat'),
                    ),
                    const SizedBox(height: 10),
                    Tooltip(
                      message: 'Click the button above to start a new chat',
                      child: Icon(
                        Icons.help_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
