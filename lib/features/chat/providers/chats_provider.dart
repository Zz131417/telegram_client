import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/logger.dart';
import '../../../models/chat.dart';
import '../../../models/message.dart';
import '../../../services/td_service.dart';

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
  // 置顶集合：与拉取的会话列表解耦，刷新后依然保持置顶状态。
  final Set<String> _pinnedIds = {};

  List<Chat> get chats {
    if (_pinnedIds.isEmpty) return _chats;
    final sorted = [..._chats];
    sorted.sort((a, b) {
      final pa = _pinnedIds.contains(a.id);
      final pb = _pinnedIds.contains(b.id);
      if (pa == pb) return 0; // 保持原有（按时间）顺序
      return pa ? -1 : 1; // 置顶的排到最前
    });
    return sorted
        .map((c) => c.copyWith(isPinned: _pinnedIds.contains(c.id)))
        .toList();
  }

  bool get loading => _loading;

  /// 切换某个会话的置顶状态。
  void togglePin(String id) {
    if (_pinnedIds.contains(id)) {
      _pinnedIds.remove(id);
    } else {
      _pinnedIds.add(id);
    }
    notifyListeners();
  }

  Future<void> load() async {
    log.i('Chats', '加载会话列表');
    _loading = true;
    notifyListeners();
    try {
      _chats = await _service.loadChats();
    } catch (e, st) {
      log.e('Chats', 'loadChats 失败', e, st);
    }
    _loading = false;
    notifyListeners();
  }

  Chat? chatById(String id) =>
      _chats.where((c) => c.id == id).firstOrNull;

  void _onNewMessage(Message message) {
    log.d('Chats', '新消息 chat=${message.chatId} outgoing=${message.isOutgoing}');
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
