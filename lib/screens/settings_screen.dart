import 'package:flutter/material.dart';

import '../core/settings_store.dart';
import 'import_screen.dart';
import 'plugins_screen.dart';
import 'proxy_screen.dart';

/// 设置页：代理、插件、导入导出、主题切换。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final tm = settings.themeMode;
    final proxy = settings.proxy;
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.vpn_key_outlined),
            title: const Text('代理'),
            subtitle: Text(proxy == null
                ? '未设置'
                : '${proxy.typeLabel} ${proxy.server}:${proxy.port}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProxyScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.extension_outlined),
            title: const Text('插件管理'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PluginsScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.import_export_outlined),
            title: const Text('导入 / 导出配置'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ImportScreen()),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text('主题', style: TextStyle(color: Colors.grey)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'system',
                  label: Text('跟随系统'),
                  icon: Icon(Icons.brightness_auto),
                ),
                ButtonSegment(
                  value: 'light',
                  label: Text('浅色'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: 'dark',
                  label: Text('深色'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {tm},
              onSelectionChanged: (s) async {
                await settings.setThemeMode(s.first);
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
