import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/plugin_manager.dart';
import '../models/message.dart';
import '../theme/app_theme.dart';

/// 消息气泡：进屏时滑入 + 淡入，自己发的靠右、对方的靠左。
/// 「紧凑气泡」插件开启时减小内边距，单屏显示更多内容。
/// 布局随主题预设变化：Telegram X 下自己发的消息用主色实心气泡（白字）。
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});
  final Message message;

  @override
  Widget build(BuildContext context) {
    final chat = context.chat;
    final layout = context.layout;
    final compact = plugins.isEnabled('compact_bubbles');
    final maxWidth = MediaQuery.of(context).size.width * 0.74;
    final outgoing = message.isOutgoing;
    final ownSolid = layout.ownBubbleSolid && outgoing;
    final bg = ownSolid
        ? Theme.of(context).colorScheme.primary
        : (outgoing
            ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
            : chat.bubble);
    final fg = ownSolid ? Colors.white : chat.onBubble;
    final hintFg = ownSolid ? Colors.white70 : chat.hint;
    final radius = layout.bubbleRadius;
    final br = layout.ownBubbleSolid
        ? BorderRadius.circular(radius)
        : BorderRadius.only(
            topLeft: Radius.circular(radius),
            topRight: Radius.circular(radius),
            bottomLeft: Radius.circular(outgoing ? radius : 4),
            bottomRight: Radius.circular(outgoing ? 4 : radius),
          );
    return Align(
      alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
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
          color: bg,
          borderRadius: br,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: fg,
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
                  style: TextStyle(color: hintFg, fontSize: 11),
                ),
                if (outgoing) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.status == MessageStatus.read
                        ? Icons.done_all
                        : Icons.done,
                    size: 14,
                    color: message.status == MessageStatus.read
                        ? (ownSolid ? Colors.white70 : Theme.of(context).colorScheme.primary)
                        : hintFg,
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
          begin: outgoing ? 0.12 : -0.12,
          end: 0,
          duration: 240.ms,
          curve: Curves.easeOutCubic,
        );
  }

  String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
