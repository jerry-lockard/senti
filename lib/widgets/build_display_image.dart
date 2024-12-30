import 'dart:io';
import 'package:flutter/material.dart';
import 'package:senti/utility/assets_manager.dart';

class BuildDisplayImage extends StatelessWidget {
  const BuildDisplayImage({
    super.key,
    required this.file,
    required this.userImage,
    required this.onPressed,
    this.borderColor = Colors.blue,
    this.borderWidth = 2.0,
  });

  final File? file;
  final String userImage;
  final VoidCallback onPressed;
  final Color borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60.0,
          backgroundColor: Colors.grey[200],
          backgroundImage: getImageToShow(),
          child: ClipOval(
            child:
                getImageToShow() != null
                    ? null
                    : const CircularProgressIndicator(),
          ),
          onBackgroundImageError:
              (exception, stackTrace) =>
                  Icon(Icons.error, color: Colors.red, size: 60.0),
        ),
        Positioned(
          bottom: 0.0,
          right: 0.0,
          child: Tooltip(
            message: 'Change Image',
            child: InkWell(
              onTap: onPressed,
              child: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                radius: 20.0,
                child: Icon(Icons.camera_alt, color: Colors.white),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0.0,
          left: 0.0,
          child: Tooltip(
            message: 'Remove Image',
            child: InkWell(
              onTap: () {
                // Implement remove image logic here
              },
              child: const CircleAvatar(
                backgroundColor: Colors.red,
                radius: 20.0,
                child: Icon(Icons.delete, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  getImageToShow() {
    if (file != null) {
      return FileImage(File(file!.path)) as ImageProvider<Object>;
    } else if (userImage.isNotEmpty) {
      return FileImage(File(userImage)) as ImageProvider<Object>;
    } else {
      return const AssetImage(AssetsMenager.userIcon);
    }
  }
}
