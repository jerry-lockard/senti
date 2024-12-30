import 'package:flutter/material.dart';

void showMyAnimatedDialog({
  required BuildContext context,
  required String title,
  required String content,
  required String actionText,
  required Function(bool) onActionPressed,
  Widget? customTitle,
  Widget? customContent,
  List<Widget>? customActions,
  Duration transitionDuration = const Duration(milliseconds: 200),
  Curve scaleCurve = Curves.easeInOut,
  Curve fadeCurve = Curves.easeIn,
}) async {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    transitionDuration: transitionDuration,
    pageBuilder: (context, animation, secondaryAnimation) {
      return Container();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: Tween<double>(
          begin: 0.5,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: scaleCurve)),
        child: FadeTransition(
          opacity: animation.drive(CurveTween(curve: fadeCurve)),
          child: AlertDialog(
            title: customTitle ?? Text(title, textAlign: TextAlign.center),
            content:
                customContent ?? Text(content, textAlign: TextAlign.center),
            actions:
                customActions ??
                [
                  TextButton(
                    onPressed: () {
                      onActionPressed(false);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      onActionPressed(true);
                      Navigator.of(context).pop();
                    },
                    child: Text(actionText),
                  ),
                ],
          ),
        ),
      );
    },
  );
}
