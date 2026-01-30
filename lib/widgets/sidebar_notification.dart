import 'package:flutter/material.dart';

/// A notification widget that displays messages inside the sidebar
class SidebarNotification extends StatelessWidget {
  final String? message;
  final VoidCallback? onDismiss;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  const SidebarNotification({
    super.key,
    this.message,
    this.onDismiss,
    this.backgroundColor = const Color(0xFFE65100),
    this.textColor = Colors.white,
    this.icon = Icons.info_outline,
  });

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.15),
        border: Border(
          top: BorderSide(color: backgroundColor.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: backgroundColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message!,
              style: TextStyle(color: backgroundColor, fontSize: 12),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                size: 14,
                color: backgroundColor.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }
}

/// A controller to manage sidebar notifications with auto-dismiss
class SidebarNotificationController {
  String? _message;
  VoidCallback? _listener;

  String? get message => _message;

  void show(String message, {Duration duration = const Duration(seconds: 3)}) {
    _message = message;
    _listener?.call();

    Future.delayed(duration, () {
      if (_message == message) {
        dismiss();
      }
    });
  }

  void dismiss() {
    _message = null;
    _listener?.call();
  }

  void addListener(VoidCallback listener) {
    _listener = listener;
  }

  void removeListener() {
    _listener = null;
  }
}
