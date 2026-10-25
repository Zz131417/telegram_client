import '../models/chat.dart';
import '../models/message.dart';
import 'mock_data.dart';

/// TDLib 接入层（桩）。
///
/// 现在用 Mock 数据驱动 UI。要接真实 Telegram：
///   1. 在 pubspec 启用 `tdlib` 依赖
///   2. 初始化 TdClient，setTdlibParameters(apiId, apiHash, ...)
///   3. 监听 update：authorizationStateWaitPhoneNumber → 填手机号 → 验证码 → ready
///   4. 把下面两个方法换成 TDLib 的 getChats / getChatHistory 调用
///   5. 收到的 updateNewMessage 推送进 ChatsProvider
abstract class TdService {
  Future<List<Chat>> loadChats();
  Future<List<Message>> loadMessages(String chatId);
}

/// 默认实现：Mock。后面加一个 TdLibServiceImpl 替换它即可。
class MockTdService implements TdService {
  @override
  Future<List<Chat>> loadChats() async {
    // 模拟网络延迟，让列表进场动画更自然
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return MockData.chats;
  }

  @override
  Future<List<Message>> loadMessages(String chatId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return MockData.messagesFor(chatId);
  }
}
