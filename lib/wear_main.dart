import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'config/credentials.dart';
import 'core/logger.dart';
import 'models/chat.dart';
import 'services/td_lib_service.dart';

/// Wear OS 入口：手表 companion 界面。
///
/// 登录方式：**仅扫码登录**（Telegram QR 登录）。启动后用内置官方凭据初始化
/// TDLib，调用 `qrCodeAuthentication` 拿到二维码，用已登录的手机扫一扫即可授权本设备。
/// 授权成功后展示最近会话。会话在本地持久化，重开 App 若仍在授权期内会直接进入会话，
/// 无需重复扫码。
///
/// 布局针对手表屏做了放大适配：圆屏用更大内边距避开表圈，二维码按屏高比例放大到
/// 可扫描尺寸；头像 / 文字均比早期版本更大，便于小屏阅读。
void main() => runApp(const WearApp());

class WearApp extends StatelessWidget {
  const WearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telegram',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const WearHome(),
    );
  }
}

class WearHome extends StatefulWidget {
  const WearHome({super.key});

  @override
  State<WearHome> createState() => _WearHomeState();
}

class _WearHomeState extends State<WearHome> {
  final TdLibServiceImpl _service = TdLibServiceImpl();
  List<Chat> _chats = const [];
  bool _loading = true;
  bool _ready = false;
  bool _error = false;
  String? _qrText;
  bool _qrRequested = false;
  StreamSubscription<Map<String, dynamic>>? _sub;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      // 手表 companion 使用内置官方凭据即可。
      Credentials.useAndroid();
      await _service.init();
      _sub = _service.updates.listen(_onUpdate);
    } catch (e) {
      log.e('Wear', 'init 失败', e);
      if (mounted) setState(() => _error = true);
    }
  }

  void _onUpdate(Map<String, dynamic> u) {
    if (u['@type'] != 'updateAuthorizationState') return;
    final st = (u['authorization_state'] ?? const <String, dynamic>{}) as Map;
    final type = st['@type'];
    if (type == 'authorizationStateWaitPhoneNumber') {
      // 授权流程就绪后，发起扫码登录（仅一次）。
      if (!_qrRequested) {
        _qrRequested = true;
        _service.send({'@type': 'qrCodeAuthentication'});
      }
    } else if (type == 'authorizationStateWaitQrCode') {
      // 兼容不同 TDLib 版本的字段命名（qrCode.text / link / url）。
      final qc = (st['qrCode'] ?? const <String, dynamic>{}) as Map;
      String? text = qc['text'] as String?;
      text ??= st['link'] as String?;
      text ??= st['url'] as String?;
      if (text != null && mounted) {
        setState(() => _qrText = text);
      }
    } else if (type == 'authorizationStateReady') {
      if (mounted) setState(() => _ready = true);
      _loadChats();
    } else if (type == 'authorizationStateClosed' ||
        type == 'authorizationStateLoggingOut') {
      // 会话失效，重新发起扫码。
      if (mounted) setState(() => _qrText = null);
      _qrRequested = false;
      _service.send({'@type': 'qrCodeAuthentication'});
    }
  }

  Future<void> _loadChats() async {
    try {
      final chats = await _service.loadChats();
      if (mounted) setState(() {
        _chats = chats;
        _loading = false;
      });
    } catch (e) {
      log.w('Wear', 'loadChats 失败', e);
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    // 不调用 _service.dispose()：它会触发 logOut 清空本地会话。手表作为 companion
    // 应保留会话，App 关闭后由进程退出自然释放底层客户端即可。
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.of(context).padding;
    final isRound = (pad.left + pad.right) > (pad.top + pad.bottom) + 4;
    final edge = isRound ? 20.0 : 10.0;
    final size = MediaQuery.of(context).size;
    // 二维码按屏高比例放大，保证手表上可被手机扫到。
    final qrSize = ((size.width < size.height ? size.width : size.height) -
            edge * 2 -
            90)
        .clamp(120.0, 340.0);

    Widget body;
    if (_error) {
      body = const Center(
        child: Text(
          '加载失败\n请重试',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    } else if (!_ready && _qrText != null) {
      body = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '扫码登录',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          QrImageView(
            data: _qrText!,
            size: qrSize,
            version: QrVersions.auto,
            gapless: true,
          ),
          const SizedBox(height: 8),
          const Text(
            '用 Telegram 扫一扫',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      );
    } else if (!_ready) {
      body = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 3),
          SizedBox(height: 10),
          Text('准备登录…', style: TextStyle(fontSize: 14)),
        ],
      );
    } else if (_loading) {
      body = const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 3),
          SizedBox(height: 10),
          Text('加载会话…', style: TextStyle(fontSize: 14)),
        ],
      );
    } else {
      body = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.telegram, size: 28),
          const SizedBox(height: 6),
          const Text(
            'Telegram',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _chats.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final c = _chats[i];
                return Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: c.avatarColor,
                      child: Text(
                        c.title.isNotEmpty ? c.title[0] : '?',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        c.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      );
    }

    return Scaffold(
      body: Padding(padding: EdgeInsets.all(edge), child: body),
    );
  }
}
