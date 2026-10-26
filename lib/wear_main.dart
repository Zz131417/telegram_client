import 'package:flutter/material.dart';

import 'models/chat.dart';
import 'services/td_service.dart';
import 'theme/app_theme.dart';

/// Wear OS 入口：手表 companion 界面（展示最近会话）。
///
/// 与手机端共用同一套模型与主题。针对手表屏做布局适配：通过 `MediaQuery` 的
/// system padding 区分圆屏/方屏——圆屏用较大内边距避开表圈，方屏紧凑即可。
/// 手表端暂不接入完整登录流程（UX 成本过高），使用 Mock 数据展示最近会话
/// 概览，作为手机端的 glanceable companion。
///
/// 注意：未依赖 `wear` 等第三方包——该包的 Android 模块在 Flutter 3.44 的
/// AGP 8 下因缺 namespace 无法编译，会让所有 Android 构建失败；纯 Flutter
/// 的屏幕判断已能满足手表的布局适配需求。
void main() => runApp(const WearApp());

class WearApp extends StatelessWidget {
  const WearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Telegram',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
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
  final _service = MockTdService();
  List<Chat> _chats = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service
        .loadChats()
        .then((chats) {
          if (mounted) setState(() => _chats = chats);
        })
        .whenComplete(() {
          if (mounted) setState(() => _loading = false);
        });
  }

  @override
  Widget build(BuildContext context) {
    // 区分圆屏 / 方屏：Wear OS 在圆屏上会给左右 system padding 留出比上下更大的
    // 安全区（系统自动避开圆形表圈），方屏则四周均匀。据此判断——圆屏用较大内边距
    // 防表圈裁切，方屏紧凑即可。纯 Flutter 实现，无需第三方 Wear 包。
    final pad = MediaQuery.of(context).padding;
    final isRound = (pad.left + pad.right) > (pad.top + pad.bottom) + 4;
    final edge = isRound ? 24.0 : 8.0;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(edge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.telegram, size: 22),
            const SizedBox(height: 4),
            const Text(
              'Telegram',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            if (_loading)
              const CircularProgressIndicator(strokeWidth: 2)
            else
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _chats.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (_, i) {
                    final c = _chats[i];
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: c.avatarColor,
                          child: Text(
                            c.title.isNotEmpty ? c.title[0] : '?',
                            style: const TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            c.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
