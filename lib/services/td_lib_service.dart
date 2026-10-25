import 'dart:async';
import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';
import 'td_native.dart';

import '../config/secrets.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'auth_state.dart';
import 'td_service.dart';

/// 真实 TDLib 接入实现（基于官方 libtdjson 的 JSON 接口 + dart:ffi）。
///
/// 不依赖任何第三方 TDLib Dart 封装，所有与 FFI / JSON 协议相关的逻辑都收敛在
/// 本文件内。对外仅暴露 `TdService` 抽象与我方领域类型（Chat / Message / AuthEvent），
/// 因此 UI 与 Provider 无需改动；若 TDLib 协议字段有出入，也只需微调本文件。
class TdLibServiceImpl implements TdService {
  TdLibServiceImpl() {
    // 构造函数里同步创建底层客户端并启动接收循环；任意一步失败都通过 authEvents
    // 抛出错误，App 不会崩溃。
    try {
      _client = FfiTdClient.create();
    } catch (e) {
      _client = null;
      _auth.add(AuthEvent(AuthState.error, message: '加载 libtdjson 失败：$e'));
    }
  }

  FfiTdClient? _client;
  final _auth = StreamController<AuthEvent>.broadcast();
  final _messages = StreamController<Message>.broadcast();
  final Map<int, String> _chatTitles = {};

  @override
  Stream<AuthEvent> get authEvents => _auth.stream;

  @override
  Stream<Message> get messageUpdates => _messages.stream;

  @override
  Future<void> init() async {
    if (_client == null) return; // 已在构造时记录错误
    if (!Secrets.isConfigured) {
      _auth.add(const AuthEvent(
        AuthState.error,
        message: '未配置凭据：请在 lib/config/secrets.dart 填入 apiId / apiHash',
      ));
      return;
    }
    _client!.start(_onEvent);

    final dir = await getApplicationSupportDirectory();
    await _client!.send({
      '@type': 'setTdlibParameters',
      'parameters': {
        '@type': 'tdlibParameters',
        'use_test_dc': false,
        'database_directory': '${dir.path}/tdlib',
        'files_directory': '${dir.path}/tdlib_files',
        'database_encryption_key': '0123456789abcdef0123456789abcdef',
        'use_message_database': true,
        'use_chat_info_database': true,
        'use_secret_chats': false,
        'api_id': Secrets.apiId,
        'api_hash': Secrets.apiHash,
        'system_language_code': 'zh',
        'device_model': 'Flutter Client',
        'system_version': '1.0',
        'application_version': '0.1.0',
        'enable_storage_optimizer': true,
      },
    });
  }

  @override
  Future<void> setPhoneNumber(String phoneNumber) async {
    await _client?.send({
      '@type': 'setAuthenticationPhoneNumber',
      'phone_number': phoneNumber,
    });
  }

  @override
  Future<void> submitCode(String code) async {
    await _client?.send({'@type': 'checkAuthenticationCode', 'code': code});
  }

  @override
  Future<void> submitPassword(String password) async {
    await _client?.send({
      '@type': 'checkAuthenticationPassword',
      'password': password,
    });
  }

  @override
  Future<List<Chat>> loadChats() async {
    final c = _client;
    if (c == null) return const [];
    final res = await c.send({
      '@type': 'getChats',
      'offset_order': '9223372036854775807',
      'offset_chat_id': 0,
      'limit': 100,
    });
    final ids = (res['chat_ids'] as List?)?.cast<int>() ?? const <int>[];
    final list = await Future.wait(ids.map(_toChat));
    return list.whereType<Chat>().toList();
  }

  @override
  Future<List<Message>> loadMessages(String chatId) async {
    final c = _client;
    final cid = int.tryParse(chatId);
    if (c == null || cid == null) return const [];
    final res = await c.send({
      '@type': 'getChatHistory',
      'chat_id': cid,
      'from_message_id': 0,
      'offset': 0,
      'limit': 50,
      'only_local': false,
    });
    final items = (res['messages'] as List?) ?? const [];
    // TDLib 返回「从新到旧」，UI 需时间正序，故反转。
    return items
        .reversed
        .map(_toMessage)
        .whereType<Message>()
        .toList();
  }

  @override
  Future<void> sendMessage(String chatId, String text) async {
    final cid = int.tryParse(chatId);
    if (_client == null || cid == null) return;
    await _client!.send({
      '@type': 'sendMessage',
      'chat_id': cid,
      'input_message_content': {
        '@type': 'inputMessageText',
        'text': {'@type': 'formattedText', 'text': text},
      },
    });
    // 真实回执走 updateNewMessage，无需在此手动追加。
  }

  @override
  Future<void> dispose() async {
    await _client?.send({'@type': 'logOut'});
    _client?.dispose();
    await _auth.close();
    await _messages.close();
  }

  // ---- 事件分发 ----

  void _onEvent(Map<String, dynamic> msg) {
    final type = msg['@type'];
    if (type == 'updateAuthorizationState') {
      _onAuthState(msg['authorization_state'] ?? const {});
    } else if (type == 'updateNewMessage') {
      final m = _toMessage(msg['message']);
      if (m != null) _messages.add(m);
    } else if (type == 'updateNewChat') {
      final chat = msg['chat'] ?? const {};
      final id = chat['id'];
      if (id is int) _chatTitles[id] = chat['title']?.toString() ?? '';
    }
  }

  void _onAuthState(Map<String, dynamic> state) {
    final type = state['@type'];
    switch (type) {
      case 'authorizationStateWaitPhoneNumber':
        _auth.add(const AuthEvent(AuthState.waitPhoneNumber));
      case 'authorizationStateWaitCode':
        _auth.add(const AuthEvent(AuthState.waitCode));
      case 'authorizationStateWaitPassword':
        _auth.add(const AuthEvent(AuthState.waitPassword));
      case 'authorizationStateReady':
        _auth.add(const AuthEvent(AuthState.ready));
      case 'authorizationStateLoggingOut':
        _auth.add(const AuthEvent(AuthState.loggingOut));
      case 'authorizationStateClosed':
        _auth.add(const AuthEvent(AuthState.initial));
    }
  }

  // ---- 类型映射（TDLib JSON -> 领域模型） ----

  Future<Chat?> _toChat(int id) async {
    final c = _client;
    if (c == null) return null;
    final res = await c.send({'@type': 'getChat', 'chat_id': id});
    final title = res['title']?.toString() ?? '';
    _chatTitles[id] = title;
    final notif = res['notification_settings'] ?? const {};
    final muteFor = notif['mute_for'] is int ? notif['mute_for'] as int : 0;
    return Chat(
      id: id.toString(),
      title: title,
      type: _chatType(res['type'] ?? const {}),
      avatarColor: _colorFor(id),
      lastMessage: null,
      unreadCount: res['unread_count'] is int ? res['unread_count'] as int : 0,
      isMuted: muteFor > 0,
    );
  }

  Message? _toMessage(dynamic raw) {
    if (raw is! Map<String, dynamic>) return null;
    final cid = raw['chat_id'];
    if (cid is! int) return null;
    final content = raw['content'] ?? const {};
    final text = content['@type'] == 'messageText'
        ? (content['text']?['text']?.toString() ?? '')
        : '[不支持的消息类型]';
    final title = _chatTitles[cid] ?? '';
    final date = raw['date'] is int ? raw['date'] as int : 0;
    return Message(
      id: raw['id'].toString(),
      chatId: cid.toString(),
      text: text,
      senderName: (raw['is_outgoing'] == true) ? '我' : title,
      isOutgoing: raw['is_outgoing'] == true,
      time: DateTime.fromMillisecondsSinceEpoch(date * 1000),
      status: raw['is_outgoing'] == true
          ? MessageStatus.sent
          : MessageStatus.read,
    );
  }

  ChatType _chatType(Map<String, dynamic> type) {
    switch (type['@type']) {
      case 'chatTypeBasicGroup':
        return ChatType.group;
      case 'chatTypeSupergroup':
        return (type['is_channel'] == true)
            ? ChatType.channel
            : ChatType.group;
      default:
        return ChatType.private;
    }
  }

  static const _palette = [
    Color(0xFFE8846B),
    Color(0xFF5BAE8E),
    Color(0xFF8A6FE8),
    Color(0xFFE8B14C),
    Color(0xFF4C9AE8),
    Color(0xFFE86F9C),
  ];

  Color _colorFor(int id) => _palette[id.abs() % _palette.length];
}
