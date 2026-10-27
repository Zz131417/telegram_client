import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 一个可启停的插件（应用内功能模块）。
class Plugin {
  const Plugin(this.id, this.name, this.description, {this.builtIn = true});

  final String id;
  final String name;
  final String description;
  final bool builtIn;
}

/// 插件管理器（单例）：维护内置插件注册表与启用状态，状态持久化到应用私有目录。
///
/// 说明：插件是「应用内可启停的功能模块」，而非运行时加载的外部代码（Flutter AOT
/// 不支持动态加载）。部分插件会真实改变 UI（如紧凑气泡、日志浮窗），其余为预留开关，
/// 接入真实 TDLib 时再扩展其行为。
class PluginManager extends ChangeNotifier {
  PluginManager._();
  static final PluginManager instance = PluginManager._();

  static const List<Plugin> registry = [
    Plugin('compact_bubbles', '紧凑气泡',
        '减小聊天气泡内边距，单屏显示更多内容'),
    Plugin('log_float', '调试日志浮窗',
        '在聊天页显示可展开的小浮窗，实时查看最近日志'),
    Plugin('no_read_receipt', '隐藏已读回执',
        '发送后不立即上报已读（实验，真实登录时生效）'),
    Plugin('block_auto_download', '禁止自动下载',
        '不自动下载收到的媒体文件（真实登录时生效）'),
  ];

  final Set<String> _enabled = {};

  bool isEnabled(String id) => _enabled.contains(id);

  Future<void> load() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/plugins.json');
      if (await file.exists()) {
        final list =
            jsonDecode(await file.readAsString()) as List<dynamic>;
        _enabled.addAll(list.map((e) => e.toString()));
      }
    } catch (_) {}
  }

  Future<void> setEnabled(String id, bool on) async {
    if (on) {
      _enabled.add(id);
    } else {
      _enabled.remove(id);
    }
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/plugins.json');
      await file.writeAsString(jsonEncode(_enabled.toList()));
    } catch (_) {}
  }
}

/// 全局插件单例。
final plugins = PluginManager.instance;
