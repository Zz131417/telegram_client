import 'package:flutter/material.dart';

import '../core/logger.dart';
import '../core/plugin_manager.dart';

/// 插件管理页：列出内置插件，开关启停并持久化。
class PluginsScreen extends StatefulWidget {
  const PluginsScreen({super.key});

  @override
  State<PluginsScreen> createState() => _PluginsScreenState();
}

class _PluginsScreenState extends State<PluginsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('插件管理')),
      body: ListView.separated(
        padding: const EdgeInsets.all(8),
        itemCount: PluginManager.registry.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final p = PluginManager.registry[i];
          final on = plugins.isEnabled(p.id);
          return SwitchListTile(
            title: Text(p.name),
            subtitle:
                Text(p.description, style: const TextStyle(fontSize: 12)),
            value: on,
            onChanged: (v) async {
              await plugins.setEnabled(p.id, v);
              log.i('Plugin', '${p.id} -> ${v ? '启用' : '停用'}');
              setState(() {});
            },
          );
        },
      ),
    );
  }
}
