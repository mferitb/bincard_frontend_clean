import 'package:flutter/material.dart';

enum MessageType { success, error, info, warning }

class CustomMessage {
  static void show(
    BuildContext context, {
    required String message,
    MessageType type = MessageType.info,
    Duration duration = const Duration(seconds: 2),
    IconData? icon,
  }) {
    Color bgColor;
    Color textColor = Colors.white;
    IconData displayIcon = icon ?? Icons.info_outline;

    switch (type) {
      case MessageType.success:
        bgColor = Colors.green.shade600;
        displayIcon = icon ?? Icons.check_circle_outline;
        break;
      case MessageType.error:
        bgColor = Colors.red.shade600;
        displayIcon = icon ?? Icons.error_outline;
        break;
      case MessageType.warning:
        bgColor = Colors.orange.shade700;
        displayIcon = icon ?? Icons.warning_amber_rounded;
        break;
      default:
        bgColor = Colors.blue.shade600;
        displayIcon = icon ?? Icons.info_outline;
    }

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(displayIcon, color: textColor, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 16),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: bgColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      duration: duration,
      elevation: 6,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
