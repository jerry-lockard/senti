import 'dart:async';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:senti/providers/chat_provider.dart';
import 'package:senti/providers/sentiment_provider.dart'; // Added import
import 'package:senti/utility/animated_dialog.dart';
import 'package:senti/widgets/preview_images_widget.dart';
import 'package:image_picker/image_picker.dart';

class BottomChatField extends StatefulWidget {
  const BottomChatField({
    super.key,
    required this.chatProvider,
    this.onSendMessage, // Optional callback for WebSocket send
  });

  final ChatProvider chatProvider;
  final Function(String)? onSendMessage;

  @override
  State<BottomChatField> createState() => _BottomChatFieldState();
}

class _BottomChatFieldState extends State<BottomChatField> {
  final TextEditingController textController = TextEditingController();
  final FocusNode textFieldFocus = FocusNode();
  final ImagePicker _picker = ImagePicker();
  Timer? _debounce;

  @override
  void dispose() {
    textController.dispose();
    textFieldFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> sendChatMessage({
    required String message,
    required ChatProvider chatProvider,
    required bool isTextOnly,
  }) async {
    try {
      // If WebSocket send message callback is provided, use it
      if (widget.onSendMessage != null) {
        widget.onSendMessage!(message);
      }

      // Perform sentiment analysis
      final sentimentProvider = Provider.of<SentimentProvider>(
        context,
        listen: false,
      );
      sentimentProvider.analyzeSentiment(message);

      // Existing chat provider message sending logic
      await chatProvider.sentMessage(message: message, isTextOnly: isTextOnly);
    } catch (e) {
      log('error : $e');
    } finally {
      textController.clear();
      widget.chatProvider.setImagesFileList(listValue: []);
      textFieldFocus.unfocus();
    }
  }

  void pickImage() async {
    try {
      final pickedImages = await _picker.pickMultiImage(
        maxHeight: 800,
        maxWidth: 800,
        imageQuality: 95,
      );

      widget.chatProvider.setImagesFileList(listValue: pickedImages);
    } catch (e) {
      log('error : $e');
    }
  }

  void _onTextChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      // Perform text analysis or validation
      if (text.isNotEmpty) {
        // Example: Check message length
        if (text.length > 500) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Message is too long. Maximum 500 characters.'),
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Sentiment analysis integration
        final sentimentProvider = Provider.of<SentimentProvider>(
          context,
          listen: false,
        );
        sentimentProvider.analyzeSentiment(text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool hasImages =
        widget.chatProvider.imagesFileList != null &&
        widget.chatProvider.imagesFileList!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Theme.of(context).textTheme.titleLarge!.color!,
        ),
      ),
      child: Column(
        children: [
          if (hasImages) const PreviewImagesWidget(),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (hasImages) {
                    // show the delete dialog
                    showMyAnimatedDialog(
                      context: context,
                      title: 'Delete Images',
                      content: 'Are you sure you want to delete the images?',
                      actionText: 'Delete',
                      onActionPressed: (value) {
                        if (value) {
                          widget.chatProvider.setImagesFileList(listValue: []);
                        }
                      },
                    );
                  } else {
                    pickImage();
                  }
                },
                icon: Icon(
                  hasImages ? CupertinoIcons.delete : CupertinoIcons.photo,
                ),
              ),
              IconButton(
                icon: Icon(CupertinoIcons.mic),
                onPressed: () async {
                  // Implement voice input functionality
                },
              ),
              IconButton(
                icon: Icon(CupertinoIcons.smiley),
                onPressed: () async {
                  // Implement emoji picker functionality
                },
              ),
              IconButton(
                icon: Icon(CupertinoIcons.paperclip),
                onPressed: () async {
                  // Implement file picker functionality
                },
              ),
              const SizedBox(width: 5),
              Expanded(
                child: TextField(
                  focusNode: textFieldFocus,
                  controller: textController,
                  textInputAction: TextInputAction.send,
                  onSubmitted:
                      widget.chatProvider.isLoading
                          ? null
                          : (String value) {
                            if (value.isNotEmpty) {
                              sendChatMessage(
                                message: textController.text,
                                chatProvider: widget.chatProvider,
                                isTextOnly: hasImages ? false : true,
                              );
                            }
                          },
                  onChanged: _onTextChanged,
                  decoration: InputDecoration(
                    hintText: 'Enter a prompt...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap:
                    widget.chatProvider.isLoading
                        ? null
                        : () {
                          if (textController.text.isNotEmpty) {
                            sendChatMessage(
                              message: textController.text,
                              chatProvider: widget.chatProvider,
                              isTextOnly: hasImages ? false : true,
                            );
                          }
                        },
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  margin: const EdgeInsets.all(5.0),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(CupertinoIcons.arrow_up, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
