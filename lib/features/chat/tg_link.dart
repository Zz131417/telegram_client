import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import 'providers/chats_provider.dart';
import 'screens/chat_detail_screen.dart';
import '../../routes/transitions.dart';

/// 处理 tg:// 深度链接：
/// - `tg://resolve?domain=USERNAME` 按 username / 标题匹配会话
/// - `tg://openmessage?chat_id=ID`（或 user_id）按 id 匹配
/// 命中则跳转到对应会话，未命中给出提示。
void openTgUri(BuildContext context, String raw) {
  Uri? uri;
  try {
    uri = Uri.parse(raw);
  } catch (_) {
    return;
  }
  if (uri.scheme != 'tg') return;

  final provider = context.read<ChatsProvider>();
  final target = _resolve(provider, uri);
  if (target != null) {
    Navigator.of(context).push(
      SlidePageRoute(page: ChatDetailScreen(chat: target)),
    );
  } else {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text('未找到对应会话：${uri.host}${uri.path}')),
    );
  }
}

Chat? _resolve(ChatsProvider provider, Uri uri) {
  final q = uri.queryParameters;
  if (uri.host == 'resolve' || uri.path == 'resolve') {
    final domain = (q['domain'] ?? '').toLowerCase();
    if (domain.isEmpty) return null;
    return provider.chats
            .where((c) => c.username != null && c.username!.toLowerCase() == domain)
            .firstOrNull ??
        provider.chats
            .where((c) => c.title.toLowerCase().contains(domain))
            .firstOrNull;
  }
  if (uri.host == 'openmessage' || uri.path == 'openmessage') {
    final id = q['chat_id'] ?? q['user_id'] ?? '';
    return provider.chatById(id);
  }
  return null;
}
