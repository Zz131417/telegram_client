import 'dart:async';
import 'package:uni_links/uni_links.dart';
import 'tg_link.dart';

/// App 被外部 tg:// 链接拉起时，先把链接暂存到这里；
/// 等进入聊天列表（能拿到 ChatsProvider）后由 ChatsScreen 消费并跳转。
/// 同时支持「冷启动拉起」与「已运行中点链接」。
String? pendingTgLink;

StreamSubscription<String?>? _sub;

/// 初始化 uni_links：冷启动读 getInitialLink，运行中监听 linkStream。
/// 只处理 tg:// 开头，存为 pending。
void initTgDeepLinks() {
  _readInitial();
  _sub = linkStream.listen(_store, onError: (_) {});
}

Future<void> _readInitial() async {
  try {
    _store(await getInitialLink());
  } catch (_) {
    // 桌面等未注册 scheme 的平台会抛异常，忽略即可。
  }
}

void _store(String? link) {
  if (link != null && link.startsWith('tg://')) pendingTgLink = link;
}

void disposeTgDeepLinks() => _sub?.cancel();
