import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../services/td_service.dart';

class ChatsProvider extends ChangeNotifier {
  ChatsProvider(this._service) {
    // 订阅实时新消息，增量更新对应会话的最后一条 / 未读数。
    _sub = _service.messageUpdates.listen(_onNewMessage);
  }

  final TdService _service;
  TdService get service => _service;
  late final StreamSubscription<Message> _sub;

  List<Chat> _chats = const [];
  bool _loading = false;

  List<Chat> get chats => _chats;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _chats = await _service.loadChats();
    _loading = false;
    notifyListeners();
  }

  Chat? chatById(String id) =>
      _chats.where((c) => c.id == id).firstOrNull;

  void _onNewMessage(Message message) {
    _chats = _chats.map((c) {
      if (c.id != message.chatId) return c;
      final unread = message.isOutgoing ? c.unreadCount : c.unreadCount + 1;
      return c.copyWith(lastMessage: message, unreadCount: unread);
    }).toList();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
