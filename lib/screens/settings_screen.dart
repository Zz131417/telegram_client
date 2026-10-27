import 'package:flutter/material.dart';

import '../core/settings_store.dart';
import 'about_screen.dart';
import 'import_screen.dart';
import 'logs_screen.dart';
import 'plugins_screen.dart';
import 'proxy_screen.dart';

/// 设置页：按「外观 / 网络 / 扩展 / 高级」分组，逐项可点击进入。
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
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          _Section(
            title: '外观',
            children: [
              const ListTile(
                leading: Icon(Icons.palette_outlined),
                title: Text('主题'),
                subtitle: Text('亮色 / 暗色 / 跟随系统'),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'system',
                      label: Text('系统'),
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
            ],
          ),
          _Section(
            title: '网络',
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
            ],
          ),
          _Section(
            title: '扩展',
            children: [
              ListTile(
                leading: const Icon(Icons.extension_outlined),
                title: const Text('插件管理'),
                subtitle: const Text('启停内置功能模块'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PluginsScreen()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.import_export_outlined),
                title: const Text('导入 / 导出配置'),
                subtitle: const Text('迁移代理 / 主题 / 插件状态'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ImportScreen()),
                ),
              ),
            ],
          ),
          _Section(
            title: '高级',
            children: [
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('日志'),
                subtitle: const Text('查看 / 复制 / 清空运行日志'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => LogsScreen()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('关于'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 带标题的分组卡片。
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Text(
            title,
            style: TextStyle(
              color: scheme.primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
