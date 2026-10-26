import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/chat.dart';
import '../providers/chats_provider.dart';
import '../routes/transitions.dart';
import '../widgets/chat_list_tile.dart';
import 'chat_detail_screen.dart';
import 'logs_screen.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telegram', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.menu_outlined),
            tooltip: '日志',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LogsScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.load,
        edgeOffset: 8,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child: provider.loading && provider.chats.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.only(top: 6, bottom: 12),
                  itemCount: provider.chats.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 70,
                    endIndent: 16,
                  ),
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
