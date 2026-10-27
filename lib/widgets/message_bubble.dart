import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/plugin_manager.dart';
import '../models/message.dart';
import '../theme/app_theme.dart';

/// 消息气泡：进屏时滑入 + 淡入，自己发的靠右、对方的靠左。
/// 「紧凑气泡」插件开启时减小内边距，单屏显示更多内容。
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});
  final Message message;

  @override
  Widget build(BuildContext context) {
    final chat = context.chat;
    final compact = plugins.isEnabled('compact_bubbles');
    final maxWidth = MediaQuery.of(context).size.width * 0.74;
    return Align(
      alignment:
          message.isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(
          vertical: compact ? 2 : 4,
          horizontal: 12,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 5 : 9,
        ),
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: message.isOutgoing
              ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
              : chat.bubble,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isOutgoing ? 16 : 4),
            bottomRight: Radius.circular(message.isOutgoing ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: chat.onBubble,
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _hm(message.time),
                  style: TextStyle(color: chat.hint, fontSize: 11),
                ),
                if (message.isOutgoing) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.status == MessageStatus.read
                        ? Icons.done_all
                        : Icons.done,
                    size: 14,
                    color: message.status == MessageStatus.read
                        ? Theme.of(context).colorScheme.primary
                        : chat.hint,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 220.ms, curve: Curves.easeOut)
        .slideY(
          begin: message.isOutgoing ? 0.12 : -0.12,
          end: 0,
          duration: 240.ms,
          curve: Curves.easeOutCubic,
        );
  }

  String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
