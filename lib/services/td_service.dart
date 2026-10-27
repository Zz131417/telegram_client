import 'dart:async';

import '../models/chat.dart';
import '../models/message.dart';
import '../models/proxy_config.dart';
import 'auth_state.dart';
import 'mock_data.dart';

/// 数据源抽象。UI / Provider 只依赖这一层，不关心底层是 Mock 还是真实 TDLib。
///
/// 接入真实 Telegram 时，只需提供 `TdLibServiceImpl`（见 td_lib_service.dart），
/// 把本文件里 `MockTdService` 换成它即可，UI 层无需改动。
abstract class TdService {
  /// 登录状态变化流（手机号→验证码→密码→就绪）。
  Stream<AuthEvent> get authEvents;

  /// 新消息流（updateNewMessage 推送）。Provider 订阅后增量更新列表。
  Stream<Message> get messageUpdates;

  /// 初始化底层客户端并发送 TDLib 参数（apiId / apiHash / 数据库目录等）。
  Future<void> init();

  /// 提交手机号，进入「等待验证码」阶段。
  Future<void> setPhoneNumber(String phoneNumber);

  /// 提交收到的验证码。
  Future<void> submitCode(String code);

  /// 提交两步验证密码。
  Future<void> submitPassword(String password);

  /// 拉取会话列表（首次或下拉刷新）。
  Future<List<Chat>> loadChats();

  /// 拉取某个会话的历史消息。
  Future<List<Message>> loadMessages(String chatId);

  /// 发送一条文本消息。
  Future<void> sendMessage(String chatId, String text);

  /// 设置代理（SOCKS5 / MTProto）。真实登录后即时下发到 TDLib。
  Future<void> setProxy(ProxyConfig config);

  /// 清除代理。
  Future<void> clearProxy();

  /// 释放底层资源。
  Future<void> dispose();

  /// 转发一条原始 TDLib 请求（JS 插件桥接用）。返回该请求的即时响应。
  /// 具体结果通常还会以 update 形式经 [updates] 回流。
  Future<Map<String, dynamic>> send(Map<String, dynamic> query);

  /// 原始 TDLib update 流（JS 插件 `td.onUpdate` 用）。不解析、不过滤。
  Stream<Map<String, dynamic>> get updates;
}

/// 默认实现：Mock 数据驱动，无需任何凭据即可预览完整 UI 与过渡动画。
///
/// 真实接入请改用 `TdLibServiceImpl`。
class MockTdService implements TdService {
  final _auth = StreamController<AuthEvent>.broadcast();
  final _messages = StreamController<Message>.broadcast();
  final _updates = StreamController<Map<String, dynamic>>.broadcast();
  ProxyConfig? _proxy;

  @override
  Stream<AuthEvent> get authEvents => _auth.stream;

  @override
  Stream<Message> get messageUpdates => _messages.stream;

  @override
  Future<void> init() async {
    // Mock 下直接进入「已登录」，让登录页直接跳到聊天列表。
    _auth.add(const AuthEvent(AuthState.ready));
  }

  @override
  Future<void> setPhoneNumber(String phoneNumber) async =>
      _auth.add(const AuthEvent(AuthState.ready));

  @override
  Future<void> submitCode(String code) async =>
      _auth.add(const AuthEvent(AuthState.ready));

  @override
  Future<void> submitPassword(String password) async =>
      _auth.add(const AuthEvent(AuthState.ready));

  @override
  Future<List<Chat>> loadChats() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return MockData.chats;
  }

  @override
  Future<List<Message>> loadMessages(String chatId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return MockData.messagesFor(chatId);
  }

  @override
  Future<void> sendMessage(String chatId, String text) async {
    final msg = Message(
      id: '${DateTime.now().millisecondsSinceEpoch}',
      chatId: chatId,
      text: text,
      senderName: '我',
      isOutgoing: true,
      time: DateTime.now(),
    );
    // 模拟服务端回执
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _messages.add(msg);
  }

  @override
  Future<void> setProxy(ProxyConfig config) async {
    _proxy = config;
  }

  @override
  Future<void> clearProxy() async {
    _proxy = null;
  }

  @override
  Future<Map<String, dynamic>> send(Map<String, dynamic> query) async {
    // Mock 仅回显，不做真实网络请求。
    return {'@type': 'ok', 'echo': query};
  }

  @override
  Stream<Map<String, dynamic>> get updates => _updates.stream;

  @override
  Future<void> dispose() async {
    await _auth.close();
    await _messages.close();
    await _updates.close();
  }
}
