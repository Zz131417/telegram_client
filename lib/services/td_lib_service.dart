import 'dart:async';

import 'package:path_provider/path_provider.dart';
import 'package:tdlib2/td_api.dart' as td;
import 'package:tdlib2/td_client.dart';

import '../config/secrets.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'auth_state.dart';
import 'td_service.dart';

/// 真实 TDLib 接入实现。
///
/// 基于社区标准封装 `tdlib2`（底层为官方 libtdjson 的 JSON 接口，通过
/// `native_prebuilt` 在构建时自动拉取并打包各平台原生库，无需手动放置）。
///
/// 所有与第三方包强耦合的逻辑都收敛在本文件内；对外仅暴露 `TdService` 抽象
/// 与我方领域类型（Chat / Message / AuthEvent）。若 `tdlib2` 某版本字段名有出入，
/// 只需微调本文件即可，UI 与 Provider 不受影响。
class TdLibServiceImpl implements TdService {
  TdLibServiceImpl() {
    // 构造即创建原生客户端并订阅事件流（tdlib2 内部通过原生 asset / receivePort
    // 异步回传，无需手动开 isolate）。
    _client = Client.create();
    _client.updates.listen(_onEvent, onError: (_) {});
  }

  late final Client _client;
  final _auth = StreamController<AuthEvent>.broadcast();
  final _messages = StreamController<Message>.broadcast();

  // 会话 id（int）-> 标题缓存，用于映射新消息的发送者显示名。
  final Map<int, String> _chatTitles = {};

  @override
  Stream<AuthEvent> get authEvents => _auth.stream;

  @override
  Stream<Message> get messageUpdates => _messages.stream;

  @override
  Future<void> init() async {
    if (!Secrets.isConfigured) {
      _auth.add(const AuthEvent(
        AuthState.error,
        message: '未配置凭据：请在 lib/config/secrets.dart 填入 apiId / apiHash',
      ));
      return;
    }
    await _client.initialize();
    final dir = await getApplicationSupportDirectory();
    final dbDir = '${dir.path}/tdlib';
    final filesDir = '${dir.path}/tdlib_files';

    await _client.send(td.SetTdlibParameters(
      tdlibParameters: td.TdlibParameters(
        useTestDc: false,
        databaseDirectory: dbDir,
        filesDirectory: filesDir,
        // 32 字节加密密钥（示例用固定值；生产可随机生成并持久化到安全存储）。
        databaseEncryptionKey: '0123456789abcdef0123456789abcdef',
        useFileDatabase: true,
        useChatInfoDatabase: true,
        useMessageDatabase: true,
        useSecretChats: false,
        apiId: Secrets.apiId,
        apiHash: Secrets.apiHash,
        systemLanguageCode: 'zh',
        deviceModel: 'Flutter Client',
        systemVersion: '1.0',
        applicationVersion: '0.1.0',
        enableStorageOptimizer: true,
        ignoreFileNames: false,
      ),
    ));
  }

  @override
  Future<void> setPhoneNumber(String phoneNumber) async {
    await _client.send(td.SetAuthenticationPhoneNumber(phoneNumber: phoneNumber));
  }

  @override
  Future<void> submitCode(String code) async {
    await _client.send(td.CheckAuthenticationCode(code: code));
  }

  @override
  Future<void> submitPassword(String password) async {
    await _client.send(td.CheckAuthenticationPassword(password: password));
  }

  @override
  Future<List<Chat>> loadChats() async {
    final res = await _client.send(td.GetChats(
      offsetOrder: 9223372036854775807,
      offsetChatId: 0,
      limit: 100,
    ));
    if (res is! td.Chats) return const [];
    final list = await Future.wait(res.chatIds.map(_toChat));
    return list.whereType<Chat>().toList();
  }

  @override
  Future<List<Message>> loadMessages(String chatId) async {
    final cid = int.tryParse(chatId);
    if (cid == null) return const [];
    final res = await _client.send(td.GetChatHistory(
      chatId: cid,
      fromMessageId: 0,
      offset: 0,
      limit: 50,
      onlyLocal: false,
    ));
    if (res is! td.Messages) return const [];
    // TDLib 返回「从新到旧」，UI 需时间正序，故反转。
    return res.messages.reversed.map(_toMessage).whereType<Message>().toList();
  }

  @override
  Future<void> sendMessage(String chatId, String text) async {
    final cid = int.tryParse(chatId);
    if (cid == null) return;
    await _client.send(td.SendMessage(
      chatId: cid,
      inputMessageContent: td.InputMessageText(text: td.FormattedText(text: text)),
    ));
    // 真实回执走 updateNewMessage，无需在此手动追加。
  }

  @override
  Future<void> dispose() async {
    await _client.send(td.LogOut());
    await _auth.close();
    await _messages.close();
  }

  // ---- 事件分发 ----

  void _onEvent(td.TdObject event) {
    if (event is td.UpdateAuthorizationState) {
      _onAuthState(event.authorizationState);
    } else if (event is td.UpdateNewMessage) {
      final msg = _toMessage(event.message);
      if (msg != null) _messages.add(msg);
    } else if (event is td.UpdateNewChat) {
      _chatTitles[event.chat.id] = event.chat.title;
    }
  }

  void _onAuthState(td.AuthorizationState state) {
    if (state is td.AuthorizationStateWaitPhoneNumber) {
      _auth.add(const AuthEvent(AuthState.waitPhoneNumber));
    } else if (state is td.AuthorizationStateWaitCode) {
      _auth.add(const AuthEvent(AuthState.waitCode));
    } else if (state is td.AuthorizationStateWaitPassword) {
      _auth.add(const AuthEvent(AuthState.waitPassword));
    } else if (state is td.AuthorizationStateReady) {
      _auth.add(const AuthEvent(AuthState.ready));
    } else if (state is td.AuthorizationStateLoggingOut) {
      _auth.add(const AuthEvent(AuthState.loggingOut));
    } else if (state is td.AuthorizationStateClosed) {
      _auth.add(const AuthEvent(AuthState.initial));
    }
  }

  // ---- 类型映射（TDLib -> 领域模型） ----

  Future<Chat?> _toChat(int id) async {
    final res = await _client.send(td.GetChat(chatId: id));
    if (res is! td.Chat) return null;
    final c = res;
    _chatTitles[c.id] = c.title;
    final notif = c.notificationSettings;
    return Chat(
      id: c.id.toString(),
      title: c.title,
      type: _chatType(c.type),
      avatarColor: _colorFor(c.id),
      lastMessage: null,
      unreadCount: c.unreadCount,
      isMuted: notif != null && notif.muteFor > 0,
    );
  }

  Message? _toMessage(td.Message m) {
    final text = m.content is td.MessageText
        ? (m.content as td.MessageText).text.text
        : '[不支持的消息类型]';
    final title = _chatTitles[m.chatId] ?? '';
    return Message(
      id: m.id.toString(),
      chatId: m.chatId.toString(),
      text: text,
      senderName: m.isOutgoing ? '我' : title,
      isOutgoing: m.isOutgoing,
      time: DateTime.fromMillisecondsSinceEpoch(m.date * 1000),
      status: m.isOutgoing ? MessageStatus.sent : MessageStatus.read,
    );
  }

  ChatType _chatType(td.ChatType type) {
    if (type is td.ChatTypePrivate || type is td.ChatTypeSecret) {
      return ChatType.private;
    } else if (type is td.ChatTypeBasicGroup) {
      return ChatType.group;
    } else if (type is td.ChatTypeSupergroup) {
      return (type as td.ChatTypeSupergroup).isChannel
          ? ChatType.channel
          : ChatType.group;
    }
    return ChatType.private;
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
