import 'dart:async';
import 'dart:math';

import 'package:path_provider/path_provider.dart';
import 'package:tdlib/tdlib.dart';

import '../config/secrets.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'auth_state.dart';
import 'td_service.dart';

/// 真实 TDLib 接入实现。
///
/// 依赖社区标准封装 `tdlib`（底层是官方 libtdjson 的 JSON 接口）。
/// 所有与第三方包强耦合的逻辑都收敛在本文件内；对外仅暴露 `TdService` 抽象
/// 与我方领域类型（Chat / Message / AuthEvent），因此若 `tdlib` 包版本 API 有
/// 出入，只需微调本文件即可，UI 与 Provider 不受影响。
///
/// 各平台还需放置原生 `libtdjson`：
///   Android -> android/app/src/main/jniLibs/<abi>/libtdjson.so
///   iOS     -> 作为 framework/dylib 链接进 Runner
///   macOS   -> 拷到 Runner Frameworks 或 app 包内
///   Windows -> tdjson.dll 放 exe 同级目录
///   Linux   -> libtdjson.so 放可执行同级目录或系统 lib 路径
class TdLibServiceImpl implements TdService {
  TdLibServiceImpl() {
    // 构造即启动原生客户端并监听事件流（tdlib 包内部用 RawReceivePort 异步回传，
    // 不需要手动开 isolate）。
    _td = Tdlib();
    _td.receiver.listen(_onEvent, onError: (e) {
      _auth.add(AuthEvent(AuthState.error, message: e.toString()));
    });
  }

  late final Tdlib _td;
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
    final dir = await getApplicationSupportDirectory();
    final dbDir = '${dir.path}/tdlib';
    final filesDir = '${dir.path}/tdlib_files';

    await _td.send(SetTdlibParameters(
      tdlibParameters: TdlibParameters(
        apiId: Secrets.apiId,
        apiHash: Secrets.apiHash,
        databaseDirectory: dbDir,
        filesDirectory: filesDir,
        // 32 字节加密密钥（示例用固定值；生产可随机生成并持久化到安全存储）。
        databaseEncryptionKey: '0123456789abcdef0123456789abcdef',
        useMessageDatabase: true,
        useSecretChats: false,
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
    await _td.send(SetAuthenticationPhoneNumber(phoneNumber: phoneNumber));
  }

  @override
  Future<void> submitCode(String code) async {
    await _td.send(CheckAuthenticationCode(code: code));
  }

  @override
  Future<void> submitPassword(String password) async {
    await _td.send(CheckAuthenticationPassword(password: password));
  }

  @override
  Future<List<Chat>> loadChats() async {
    final chatsRes = await _td.invoke(GetChats(
      offsetOrder: 9223372036854775807,
      offsetChatId: 0,
      limit: 100,
    ));
    final ids = (chatsRes as Chats).chatIds;
    final list = await Future.wait(ids.map(_toChat));
    return list.whereType<Chat>().toList();
  }

  @override
  Future<List<Message>> loadMessages(String chatId) async {
    final cid = int.tryParse(chatId);
    if (cid == null) return const [];
    final res = await _td.invoke(GetChatHistory(
      chatId: cid,
      fromMessageId: 0,
      offset: 0,
      limit: 50,
      onlyLocal: false,
    ));
    final items = (res as Messages).messages;
    // TDLib 返回为「从新到旧」，UI 需要时间正序，故反转。
    return items.reversed.map(_toMessage).whereType<Message>().toList();
  }

  @override
  Future<void> sendMessage(String chatId, String text) async {
    final cid = int.tryParse(chatId);
    if (cid == null) return;
    await _td.send(SendMessage(
      chatId: cid,
      inputMessageContent: InputMessageText(
        text: FormattedText(text: text),
      ),
    ));
    // 真实回执走 updateNewMessage，无需在此手动追加。
  }

  @override
  Future<void> dispose() async {
    await _td.send(LogOut());
    await _auth.close();
    await _messages.close();
  }

  // ---- 事件分发 ----

  void _onEvent(TdObject event) {
    if (event is UpdateAuthorizationState) {
      _onAuthState(event.authorizationState);
    } else if (event is UpdateNewMessage) {
      final msg = _toMessage(event.message);
      if (msg != null) _messages.add(msg);
      // 同步更新会话的 lastMessage 缓存（provider 也会监听此流）
    } else if (event is UpdateNewChat) {
      _chatTitles[event.chat.id] = event.chat.title;
    } else if (event is UpdateChatLastMessage) {
      _chatTitles[event.chatId] = _chatTitles[event.chatId] ?? '';
    }
  }

  void _onAuthState(AuthorizationState state) {
    if (state is AuthorizationStateWaitPhoneNumber) {
      _auth.add(const AuthEvent(AuthState.waitPhoneNumber));
    } else if (state is AuthorizationStateWaitCode) {
      _auth.add(const AuthEvent(AuthState.waitCode));
    } else if (state is AuthorizationStateWaitPassword) {
      _auth.add(const AuthEvent(AuthState.waitPassword));
    } else if (state is AuthorizationStateReady) {
      _auth.add(const AuthEvent(AuthState.ready));
    } else if (state is AuthorizationStateLoggingOut) {
      _auth.add(const AuthEvent(AuthState.loggingOut));
    } else if (state is AuthorizationStateClosed) {
      _auth.add(const AuthEvent(AuthState.initial));
    }
  }

  // ---- 类型映射（TDLib -> 领域模型） ----

  Future<Chat?> _toChat(int id) async {
    final res = await _td.invoke(GetChat(chatId: id));
    if (res is! Chat) return null;
    final c = res;
    _chatTitles[c.id] = c.title;
    return Chat(
      id: c.id.toString(),
      title: c.title,
      type: _chatType(c.type),
      avatarColor: _colorFor(c.id),
      lastMessage: null,
      unreadCount: c.unreadCount,
      isMuted: c.notificationSettings?.muteFor != null &&
          c.notificationSettings!.muteFor! > 0,
    );
  }

  Message? _toMessage(dynamic m) {
    if (m is! Message) return null;
    final msg = m;
    final text = _extractText(msg.content);
    final title = _chatTitles[msg.chatId] ?? '';
    return Message(
      id: msg.id.toString(),
      chatId: msg.chatId.toString(),
      text: text,
      senderName: msg.isOutgoing ? '我' : title,
      isOutgoing: msg.isOutgoing,
      time: DateTime.fromMillisecondsSinceEpoch(msg.date * 1000),
      status: msg.isOutgoing ? MessageStatus.sent : MessageStatus.read,
    );
  }

  String _extractText(dynamic content) {
    if (content is MessageText) return content.text.text;
    return '[不支持的消息类型]';
  }

  ChatType _chatType(dynamic type) {
    if (type is ChatTypePrivate || type is ChatTypeSecret) {
      return ChatType.private;
    } else if (type is ChatTypeBasicGroup) {
      return ChatType.group;
    } else if (type is ChatTypeSupergroup) {
      final isChannel = (type as ChatTypeSupergroup).isChannel;
      return isChannel ? ChatType.channel : ChatType.group;
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
