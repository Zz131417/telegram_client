import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/logger.dart';
import '../../../core/plugin_manager.dart';
import '../../../core/settings_store.dart';
import '../../../models/proxy_config.dart';

/// 导入 / 导出配置页。
///
/// 导出：把当前「代理 + 主题 + 已启用插件」序列化为 JSON，可复制保存。
/// 导入：粘贴同样的 JSON，应用代理 / 主题 / 插件状态（持久化）。
class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final _text = TextEditingController();
  String _msg = '';

  String _exportJson() => jsonEncode({
        'proxy': settings.proxy?.toJson(),
        'themeMode': settings.themeMode,
        'plugins': PluginManager.registry
            .where((p) => plugins.isEnabled(p.id))
            .map((p) => p.id)
            .toList(),
      });

  Future<void> _copyExport() async {
    await Clipboard.setData(ClipboardData(text: _exportJson()));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('已复制导出 JSON')));
    }
  }

  Future<void> _doImport() async {
    try {
      final j = jsonDecode(_text.text) as Map<String, dynamic>;
      if (j.containsKey('proxy')) {
        settings.proxy =
            ProxyConfig.fromJsonOrNull(j['proxy'] as Map<String, dynamic>?);
      }
      if (j.containsKey('themeMode')) {
        settings.themeMode = j['themeMode'] as String? ?? 'system';
      }
      if (j.containsKey('plugins')) {
        final list =
            (j['plugins'] as List).map((e) => e.toString()).toSet();
        for (final p in PluginManager.registry) {
          await plugins.setEnabled(p.id, list.contains(p.id));
        }
      }
      await settings.save();
      log.i('Import', '已导入配置');
      setState(() => _msg = '导入成功 ✅（主题已应用，下次启动生效）');
    } catch (e) {
      log.e('Import', '导入失败', e);
      setState(() => _msg = '导入失败：$e');
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导入 / 导出配置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('导出当前配置',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              _exportJson(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          TextButton.icon(
            onPressed: _copyExport,
            icon: const Icon(Icons.copy_outlined),
            label: const Text('复制导出 JSON'),
          ),
          const Divider(height: 32),
          const Text('导入配置（粘贴上方格式 JSON）',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _text,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: '在此粘贴配置 JSON…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _doImport,
            icon: const Icon(Icons.upload_outlined),
            label: const Text('导入'),
          ),
          if (_msg.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_msg,
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ],
      ),
    );
  }
}
