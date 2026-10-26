import 'package:flutter/material.dart';

import 'models/chat.dart';
import 'services/td_service.dart';
import 'theme/app_theme.dart';

/// Wear OS 入口：手表 companion 界面（展示最近会话）。
///
/// 与手机端共用同一套模型与主题。针对小表盘做布局适配：用 `MediaQuery`
/// 的短边判断是否为手表屏，圆屏/方屏统一给较大内边距避免被表圈裁切。
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
    // 手表屏短边通常较小；统一给安全内边距，避免圆屏表圈裁切内容。
    final shortest = MediaQuery.of(context).size.shortestSide;
    final pad = shortest < 320 ? 24.0 : 8.0;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(pad),
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
