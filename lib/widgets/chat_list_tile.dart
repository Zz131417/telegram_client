import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../routes/transitions.dart';
import '../theme/app_theme.dart';

/// 聊天列表项：头像（首字母色块）+ 标题 + 最后一条消息 + 未读数。
/// 布局随主题预设变化：Telegram X 下未读标题加粗、预览用主色强调、头像更小更紧凑。
class ChatListTile extends StatelessWidget {
  const ChatListTile({
    super.key,
    required this.chat,
    required this.index,
    required this.onTap,
  });
  final Chat chat;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final layout = context.layout;
    final unread = chat.unreadCount > 0;
    final titleWeight = unread
        ? (layout.unreadTitleBold ? FontWeight.w700 : FontWeight.w600)
        : (layout.unreadTitleBold ? FontWeight.w500 : FontWeight.w600);
    final previewColor = unread && layout.unreadPreviewAccent
        ? theme.colorScheme.primary
        : theme.hintColor;
    return StaggeredList(
      index: index,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: layout.listTileVerticalPadding,
            ),
            child: Row(
              children: [
                Hero(
                  tag: 'avatar-${chat.id}',
                  child: CircleAvatar(
                    radius: layout.avatarRadius,
                    backgroundColor: chat.avatarColor,
                    backgroundImage: chat.avatarUrl != null
                        ? NetworkImage(chat.avatarUrl!)
                        : null,
                    child: chat.avatarUrl == null
                        ? Text(
                            chat.title.isNotEmpty ? chat.title[0] : '',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: layout.avatarRadius * 0.62,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.title,
                              style: TextStyle(
                                fontWeight: titleWeight,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (chat.lastMessage != null)
                            Text(
                              _hm(chat.lastMessage!.time),
                              style: TextStyle(
                                color: theme.hintColor,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.lastMessage?.text ?? '',
                              style: TextStyle(
                                color: previewColor,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unread)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                chat.unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
