import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/logger.dart';

/// 日志查看页：展示内存中的日志记录，支持复制、清空、刷新，并显示落盘文件路径。
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  @override
  Widget build(BuildContext context) {
    final entries = log.buffer.reversed.toList();
    final file = log.file;
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: '复制全部',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: log.exportText()));
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已复制全部日志到剪贴板')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: '刷新',
            onPressed: () => setState(() {}),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清空内存日志',
            onPressed: () {
              log.clearBuffer();
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (file != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '落盘文件：${file.path}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('暂无日志'))
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 12, endIndent: 12),
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      final color = _colorFor(e.level);
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 3, right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: color.withAlpha(38),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              e.level.label,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          Expanded(
                            child: SelectableText(
                              e.toLine(),
                              style: const TextStyle(
                                  fontSize: 12, fontFamily: 'monospace'),
                            ),
                          ),
                        ],
                      );
                    },
                  ).animate().fadeIn(duration: 200.ms),
          ),
        ],
      ),
    );
  }

  Color _colorFor(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        return Colors.grey;
      case LogLevel.debug:
        return Colors.blue;
      case LogLevel.info:
        return Colors.green;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.error:
        return Colors.red;
    }
  }
}
