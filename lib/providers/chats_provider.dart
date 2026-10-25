import 'package:flutter/material.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../services/td_service.dart';

class ChatsProvider extends ChangeNotifier {
  ChatsProvider(this._service);

  final TdService _service;

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

  void updateLastMessage(String chatId, Message message) {
    _chats = _chats.map((c) {
      if (c.id != chatId) return c;
      final unread = message.isOutgoing ? c.unreadCount : c.unreadCount + 1;
      return c.copyWith(lastMessage: message, unreadCount: unread);
    }).toList();
    notifyListeners();
  }
}
