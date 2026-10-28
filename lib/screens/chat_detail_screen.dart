import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../services/service_notifier.dart';
import '../services/td_service.dart';
import '../widgets/message_bubble.dart';

/// 聊天详情页：真实拉取历史 + 订阅新消息 + 发送文本。
class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key, required this.chat});
  final Chat chat;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  List<Message> _messages = const [];
  bool _loading = true;
  late final StreamSubscription<Message> _sub;

  @override
  void initState() {
    super.initState();
    final sv = context.read<ServiceNotifier>().service;
    _sub = sv.messageUpdates.listen(_onNewMessage);
    _load(sv);
  }

  Future<void> _load(TdService sv) async {
    final list = await sv.loadMessages(widget.chat.id);
    if (mounted) {
      setState(() {
        _messages = list;
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  void _onNewMessage(Message msg) {
    if (msg.chatId != widget.chat.id) return;
    setState(() => _messages = [..._messages, msg]);
    _scrollToBottom();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    // 先本地乐观插入，保证即时反馈；真实回执会通过 updateNewMessage 再次到达。
    final optimistic = Message(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      chatId: widget.chat.id,
      text: text,
      senderName: '我',
      isOutgoing: true,
      time: DateTime.now(),
    );
    setState(() {
      _messages = [..._messages, optimistic];
      _controller.clear();
    });
    _scrollToBottom();
    context.read<ServiceNotifier>().service.sendMessage(widget.chat.id, text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 32,
        title: Row(
          children: [
            Hero(
              tag: 'avatar-${widget.chat.id}',
              child: CircleAvatar(
                radius: 18,
                backgroundColor: widget.chat.avatarColor,
                child: Text(
                  widget.chat.title.isNotEmpty ? widget.chat.title[0] : '',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chat.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!_loading && _messages.isNotEmpty)
                    Text(
                      '在线',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.phone_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) =>
                        MessageBubble(message: _messages[i]),
                  ),
          ),
          _inputBar(theme),
        ],
      ),
    );
  }

  Widget _inputBar(ThemeData theme) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(context.layout.inputBarRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.emoji_emotions_outlined),
              onPressed: () {},
              color: theme.hintColor,
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: '消息',
                  border: InputBorder.none,
                  fillColor: Colors.transparent,
                  filled: false,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _send(),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: IconButton(
                key: ValueKey(_controller.text.isEmpty),
                icon: Icon(
                  _controller.text.isEmpty ? Icons.mic_outlined : Icons.send,
                ),
                color: theme.colorScheme.primary,
                onPressed: _send,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
