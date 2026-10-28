import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/logger.dart';
import '../../../core/plugin_manager.dart';
import '../../../models/chat.dart';
import '../providers/chats_provider.dart';
import '../../../routes/transitions.dart';
import '../widgets/chat_list_tile.dart';
import './chat_detail_screen.dart';
import '../../settings/screens/logs_screen.dart';
import '../../settings/screens/settings_screen.dart';

/// 聊天列表页：下拉刷新 + 错峰进场动画；点击用 SlidePageRoute 滑入详情。
class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ChatsProvider>().load());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatsProvider>();
    final layout = context.layout;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telegram', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '设置',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: provider.load,
            edgeOffset: 8,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: provider.loading && provider.chats.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      padding: const EdgeInsets.only(top: 6, bottom: 12),
                      itemCount: provider.chats.length,
                      separatorBuilder: (_, __) => layout.showDividers
                          ? const Divider(height: 1, indent: 70, endIndent: 16)
                          : const SizedBox.shrink(),
                      itemBuilder: (context, i) {
                        final chat = provider.chats[i];
                        return ChatListTile(
                          chat: chat,
                          index: i,
                          onTap: () => _openChat(context, chat),
                        );
                      },
                    ),
            ),
          ),
          if (plugins.isEnabled('log_float'))
            const Positioned(
              bottom: 84,
              right: 16,
              child: _LogFloat(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.edit_outlined),
      ).animate().scale(delay: 400.ms, duration: 260.ms, curve: Curves.easeOutBack),
    );
  }

  void _openChat(BuildContext context, Chat chat) {
    Navigator.of(context).push(
      SlidePageRoute(page: ChatDetailScreen(chat: chat)),
    );
  }
}

/// 调试日志浮窗（由「调试日志浮窗」插件控制显隐）。
class _LogFloat extends StatefulWidget {
  const _LogFloat();

  @override
  State<_LogFloat> createState() => _LogFloatState();
}

class _LogFloatState extends State<_LogFloat> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    if (!_open) {
      return FloatingActionButton.small(
        onPressed: () => setState(() => _open = true),
        tooltip: '实时日志',
        child: const Icon(Icons.bug_report),
      );
    }
    final recent = log.buffer.reversed.take(6).toList();
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxHeight: 220),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('实时日志',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _open = false),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                children: recent
                    .map((e) => Text(
                          e.toLine(),
                          style: const TextStyle(
                              fontSize: 10, fontFamily: 'monospace'),
                        ))
                    .toList(),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => LogsScreen()),
              ),
              child: const Text('完整日志'),
            ),
          ],
        ),
      ),
    );
  }
}
