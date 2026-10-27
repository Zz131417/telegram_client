import 'dart:async';
import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';
import '../core/logger.dart';
import '../core/settings_store.dart';
import '../models/proxy_config.dart';
import 'td_native.dart';

import '../config/credentials.dart';
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
    // 构造函数里同步创建底层客户端；失败仅记录，真正的错误在 init() 中发出，
    // 因为登录界面会在创建后才订阅 authEvents。
    try {
      _client = FfiTdClient.create();
      log.d('TDLib', 'FfiTdClient 创建成功');
    } catch (e) {
      _client = null;
      _loadError = '加载 libtdjson 失败：$e';
      log.e('TDLib', '加载 libtdjson 失败', e);
    }
  }

  FfiTdClient? _client;
  String? _loadError;
  int? _proxyId;
  final _updateCtl = StreamController<Map<String, dynamic>>.broadcast();
  final _auth = StreamController<AuthEvent>.broadcast();
  final _messages = StreamController<Message>.broadcast();
  final Map<int, String> _chatTitles = {};

  @override
  Stream<AuthEvent> get authEvents => _auth.stream;

  @override
  Stream<Message> get messageUpdates => _messages.stream;

  @override
  Future<void> init() async {
    if (_loadError != null) {
      log.e('TDLib', 'init 中止：$_loadError');
      _auth.add(AuthEvent(AuthState.error, message: _loadError!));
      return;
    }
    if (_client == null) {
      log.e('TDLib', 'init 中止：client 为 null');
      return; // 已在构造时记录错误
    }
    if (!Credentials.hasValue) {
      log.e('TDLib', 'init 中止：未配置凭据');
      _auth.add(const AuthEvent(
        AuthState.error,
        message: '未配置凭据：请在登录界面选择「官方」或输入自己的 api_id / apiHash',
      ));
      return;
    }
    log.i('TDLib', 'init: 启动接收循环并发送 setTdlibParameters (api_id=${Credentials.apiId})');
    _client!.start(_onEvent);
    // 若之前配置过代理，登录后自动下发。
    if (settings.proxy != null) {
      await setProxy(settings.proxy!);
    }

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
        'api_id': Credentials.apiId,
        'api_hash': Credentials.apiHash,
        'system_language_code': 'zh',
        'device_model': 'Flutter Client',
        'system_version': '1.0',
        'application_version': '0.1.0',
        'enable_storage_optimizer': true,
      },
    });
    log.d('TDLib', 'setTdlibParameters 已发送');
  }

  @override
  Future<void> setPhoneNumber(String phoneNumber) async {
    log.d('Auth', 'setPhoneNumber: ${_maskPhone(phoneNumber)}');
    await _client?.send({
      '@type': 'setAuthenticationPhoneNumber',
      'phone_number': phoneNumber,
    });
  }

  @override
  Future<void> submitCode(String code) async {
    log.d('Auth', 'checkAuthenticationCode: <${code.length}位>');
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
    final chats = list.whereType<Chat>().toList();
    log.i('TDLib', 'getChats -> 返回 ${chats.length} 个会话');
    return chats;
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
    final msgs = items
        .reversed
        .map(_toMessage)
        .whereType<Message>()
        .toList();
    log.d('TDLib', 'getChatHistory chat=$chatId -> ${msgs.length} 条消息');
    return msgs;
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
    log.d('TDLib', 'sendMessage chat=$chatId');
    // 真实回执走 updateNewMessage，无需在此手动追加。
  }

  @override
  Future<void> setProxy(ProxyConfig config) async {
    if (_client == null) {
      log.w('Proxy', 'setProxy 被调用但 client 未就绪');
      return;
    }
    log.i('Proxy', '设置代理: ${config.typeLabel} ${config.server}:${config.port}');
    final type = config.type == ProxyType.socks5
        ? {
            '@type': 'proxyTypeSocks5',
            'username': config.username,
            'password': config.password,
          }
        : {
            '@type': 'proxyTypeMtproto',
            'secret': config.password,
          };
    final res = await _client!.send({
      '@type': 'addProxy',
      'server': config.server,
      'port': config.port,
      'type': type,
    });
    final id = res['id'];
    if (id is int) {
      _proxyId = id;
      await _client!.send({'@type': 'enableProxy', 'proxy_id': id});
      log.i('Proxy', '代理已启用 id=$id');
    } else {
      log.e('Proxy', 'addProxy 返回异常: $res');
    }
  }

  @override
  Future<void> clearProxy() async {
    if (_client == null || _proxyId == null) return;
    await _client!.send({'@type': 'removeProxy', 'proxy_id': _proxyId});
    _proxyId = null;
    log.i('Proxy', '代理已移除');
  }

  @override
  Stream<Map<String, dynamic>> get updates => _updateCtl.stream;

  @override
  Future<Map<String, dynamic>> send(Map<String, dynamic> query) async {
    if (_client == null) {
      return {'@type': 'error', 'message': 'client 未就绪'};
    }
    try {
      final res = await _client!.send(query);
      return res ?? {'@type': 'ok'};
    } catch (e) {
      return {'@type': 'error', 'message': e.toString()};
    }
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
    _updateCtl.add(msg);
    log.v('TDLib', 'update: $type');
    if (type == 'updateAuthorizationState') {
      _onAuthState(msg['authorization_state'] ?? const {});
    } else if (type == 'updateNewMessage') {
      final m = _toMessage(msg['message']);
      if (m != null) {
        log.d('TDLib', 'updateNewMessage chat=${m.chatId}');
        _messages.add(m);
      }
    } else if (type == 'updateNewChat') {
      final chat = msg['chat'] ?? const {};
      final id = chat['id'];
      if (id is int) _chatTitles[id] = chat['title']?.toString() ?? '';
    }
  }

  void _onAuthState(Map<String, dynamic> state) {
    final type = state['@type'];
    log.i('Auth', '授权状态 -> $type');
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

  /// 手机号脱敏：保留前 3 后 4，中间用 **** 代替（避免日志落盘泄露隐私）。
  static String _maskPhone(String p) {
    if (p.length <= 7) return p;
    return '${p.substring(0, 3)}****${p.substring(p.length - 4)}';
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
