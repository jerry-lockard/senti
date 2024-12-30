import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting
import 'package:senti/models/message.dart';
import 'package:senti/widgets/preview_images_widget.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MyMessageWidget extends StatelessWidget {
  const MyMessageWidget({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
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
      onDoubleTap: () {
        // Show a dialog to edit the message
        showDialog(
          context: context,
          builder: (context) {
            TextEditingController controller = TextEditingController(
              text: message.message.toString(),
            );
            return AlertDialog(
              title: Text('Edit Message'),
              content: TextField(controller: controller, maxLines: null),
              actions: [
                TextButton(
                  onPressed: () {
                    // Handle message update
                    Navigator.pop(context);
                  },
                  child: Text('Save'),
                ),
              ],
            );
          },
        );
      },
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(15),
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (message.imagesUrls.isNotEmpty)
                PreviewImagesWidget(message: message),
              MarkdownBody(selectable: true, data: message.message.toString()),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('hh:mm a').format(message.timeSent),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 12,
                    color: message.isRead ? Colors.blue : Colors.grey,
                  ),
                ],
              ),
              // Optionally display read status
              // Text(message.isRead ? "Read" : "Unread", style: TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
