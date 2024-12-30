import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this import for date formatting
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class AssistantMessageWidget extends StatelessWidget {
  const AssistantMessageWidget({super.key, required this.message});

  final String message;

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
              text: message,
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
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
          ),
          padding: const EdgeInsets.all(15),
          margin: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.isEmpty)
                const SizedBox(
                  width: 50,
                  child: SpinKitThreeBounce(color: Colors.blueGrey, size: 20.0),
                )
              else
                MarkdownBody(selectable: true, data: message),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('hh:mm a').format(DateTime.now()),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.check_circle, size: 12, color: Colors.green),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
