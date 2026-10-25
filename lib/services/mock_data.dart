import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/message.dart';

/// Mock 数据：让 UI 立刻能跑、能看到过渡与动画效果。
/// 真实接入时，把 TdService 里读取聊天/消息的方法换成 TDLib 调用即可。
class MockData {
  static final List<Chat> chats = [
    Chat(
      id: 'c1',
      title: '林晚',
      type: ChatType.private,
      avatarColor: const Color(0xFFE8846B),
      lastMessage: const Message(
        id: 'm1',
        chatId: 'c1',
        text: '刚到家，路上看到超好看的晚霞 🌇',
        senderName: '林晚',
        isOutgoing: false,
        time: _t(18, 42),
      ),
      unreadCount: 2,
    ),
    Chat(
      id: 'c2',
      title: 'Flutter 中文社区',
      type: ChatType.group,
      avatarColor: const Color(0xFF5BAE8E),
      lastMessage: const Message(
        id: 'm2',
        chatId: 'c2',
        text: '本周 meetup 主题定了：Impeller 渲染管线',
        senderName: '阿杰',
        isOutgoing: false,
        time: _t(18, 30),
      ),
      unreadCount: 0,
    ),
    Chat(
      id: 'c3',
      title: '设计灵感',
      type: ChatType.channel,
      avatarColor: const Color(0xFF8A6FE8),
      lastMessage: const Message(
        id: 'm3',
        chatId: 'c3',
        text: '每日一图：极简主义配色方案',
        senderName: '设计灵感',
        isOutgoing: false,
        time: _t(17, 55),
      ),
      unreadCount: 0,
      isMuted: true,
    ),
    Chat(
      id: 'c4',
      title: '妈妈',
      type: ChatType.private,
      avatarColor: const Color(0xFFE8B14C),
      lastMessage: const Message(
        id: 'm4',
        chatId: 'c4',
        text: '记得吃饭 🍚',
        senderName: '妈妈',
        isOutgoing: false,
        time: _t(12, 10),
      ),
      unreadCount: 0,
    ),
  ];

  static List<Message> messagesFor(String chatId) {
    final base = DateTime.now();
    if (chatId == 'c1') {
      return [
        const Message(
          id: 'c1m1',
          chatId: 'c1',
          text: '在忙吗？',
          senderName: '林晚',
          isOutgoing: false,
          time: _t(18, 38),
        ),
        const Message(
          id: 'c1m2',
          chatId: 'c1',
          text: '刚开完会，怎么啦',
          senderName: '我',
          isOutgoing: true,
          time: _t(18, 39),
        ),
        const Message(
          id: 'c1m3',
          chatId: 'c1',
          text: '刚到家，路上看到超好看的晚霞 🌇',
          senderName: '林晚',
          isOutgoing: false,
          time: _t(18, 42),
        ),
      ];
    }
    if (chatId == 'c4') {
      return [
        const Message(
          id: 'c4m1',
          chatId: 'c4',
          text: '中午吃了什么',
          senderName: '妈妈',
          isOutgoing: false,
          time: _t(12, 5),
        ),
        const Message(
          id: 'c4m2',
          chatId: 'c4',
          text: '记得吃饭 🍚',
          senderName: '妈妈',
          isOutgoing: false,
          time: _t(12, 10),
        ),
      ];
    }
    return List.generate(
      6,
      (i) => Message(
        id: '${chatId}m$i',
        chatId: chatId,
        text: '这是一条示例消息 #$i，用来展示气泡进场动画',
        senderName: i.isEven ? '对方' : '我',
        isOutgoing: i.isOdd,
        time: base.subtract(Duration(minutes: (6 - i) * 3)),
      ),
    );
  }
}

DateTime _t(int h, int m) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, h, m);
}
