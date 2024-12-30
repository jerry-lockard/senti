import 'dart:io';

import 'package:flutter/material.dart';
import 'package:senti/models/message.dart';
import 'package:senti/providers/chat_provider.dart';
import 'package:provider/provider.dart';

class PreviewImagesWidget extends StatelessWidget {
  const PreviewImagesWidget({super.key, this.message});

  final Message? message;

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final messageToShow =
            message != null ? message!.imagesUrls : chatProvider.imagesFileList;
        final padding =
            message != null
                ? EdgeInsets.zero
                : const EdgeInsets.only(left: 8.0, right: 8.0);
        return Padding(
          padding: padding,
          child: SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: messageToShow!.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(4.0, 8.0, 4.0, 0.0),
                  child: GestureDetector(
                    onTap: () {
                      // Implement full-screen image viewer logic here
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => FullScreenImageViewer(
                                image: messageToShow[index] as String,
                              ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20.0),
                      child: Stack(
                        children: [
                          Image.file(
                            File(
                              message != null
                                  ? message!.imagesUrls[index]
                                  : chatProvider.imagesFileList![index].path,
                            ),
                            height: 80,
                            width: 80,
                            fit: BoxFit.cover,
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                // Implement deletion logic here
                                chatProvider.removeImageAt(index);
                              },
                            ),
                          ),
                          // Add a loading indicator if necessary
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// Example FullScreenImageViewer widget
class FullScreenImageViewer extends StatelessWidget {
  final String image;

  const FullScreenImageViewer({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Image.file(File(image))),
    );
  }
}
