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
    this.username,
    this.lastMessage,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isPinned = false,
  });

  final String id;
  final String title;
  final ChatType type;
  final Color avatarColor;
  final String? avatarUrl;
  final String? username;
  final Message? lastMessage;
  final int unreadCount;
  final bool isMuted;
  final bool isPinned;

  Chat copyWith({
    Message? lastMessage,
    int? unreadCount,
    bool? isMuted,
    bool? isPinned,
    String? username,
  }) =>
      Chat(
        id: id,
        title: title,
        type: type,
        avatarColor: avatarColor,
        avatarUrl: avatarUrl,
        username: username ?? this.username,
        lastMessage: lastMessage ?? this.lastMessage,
        unreadCount: unreadCount ?? this.unreadCount,
        isMuted: isMuted ?? this.isMuted,
        isPinned: isPinned ?? this.isPinned,
      );
}
