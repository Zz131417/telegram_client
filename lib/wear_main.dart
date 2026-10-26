import 'package:flutter/material.dart';
import 'package:wear/wear.dart';

import 'models/chat.dart';
import 'services/mock_data.dart';
import 'theme/app_theme.dart';

/// Wear OS 入口：手表 companion 界面（展示最近会话）。
///
/// 与手机端共用同一套模型与主题，但针对小圆屏做布局适配：
/// 通过 `wear` 包的 `WatchShape` 区分圆形 / 方形表盘，圆形时加大内边距
/// 避免内容被表圈裁切。手表端暂不接入完整登录流程（UX 成本过高），
/// 使用 Mock 数据展示最近会话概览，作为手机端的 glanceable companion。
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
    return WatchShape(
      builder: (ctx, shape, _) {
        final isRound = shape == WearShape.round;
        final pad = isRound ? 22.0 : 6.0;
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
      },
    );
  }
}
