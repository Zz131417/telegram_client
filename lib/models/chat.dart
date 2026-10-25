import 'package:flutter/material.dart';
import 'message.dart';

enum ChatType { private, group, channel }

class Chat {
  const Chat({
    required this.id,
    required this.title,
    required this.type,
    required this.avatarColor,
    this.avatarUrl,
    this.lastMessage,
    this.unreadCount = 0,
    this.isMuted = false,
  });

  final String id;
  final String title;
  final ChatType type;
  final Color avatarColor;
  final String? avatarUrl;
  final Message? lastMessage;
  final int unreadCount;
  final bool isMuted;

  Chat copyWith({Message? lastMessage, int? unreadCount}) => Chat(
        id: id,
        title: title,
        type: type,
        avatarColor: avatarColor,
        avatarUrl: avatarUrl,
        lastMessage: lastMessage ?? this.lastMessage,
        unreadCount: unreadCount ?? this.unreadCount,
        isMuted: isMuted,
      );
}
