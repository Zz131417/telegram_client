import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/proxy_config.dart';

/// 应用设置（单例），负责把「代理 / 主题 / 凭据偏好」持久化到应用私有目录。
///
/// 不依赖任何第三方存储库，直接用 [path_provider] + JSON 文件落地，保持构建零额外依赖。
class SettingsStore extends ChangeNotifier {
  SettingsStore._();
  static final SettingsStore instance = SettingsStore._();

  /// 当前代理（null 表示不走代理）。
  ProxyConfig? proxy;

  /// 主题亮度偏好：'system' | 'light' | 'dark'。
  String themeMode = 'system';

  /// 主题预设：'classic'（原版 Telegram）| 'x'（Telegram X）。
  String themePreset = 'classic';


  /// 上次登录选择的凭据方式（0=Android 官方 / 1=Desktop 官方 / 2=iOS-X 官方 / 3=自定义）。
  int? lastCredentialChoice;

  File? _file;

  Future<void> load() async {
    try {
      final dir = await getApplicationSupportDirectory();
      _file = File('${dir.path}/settings.json');
      if (await _file!.exists()) {
        final j =
            jsonDecode(await _file!.readAsString()) as Map<String, dynamic>;
        proxy = ProxyConfig.fromJsonOrNull(j['proxy'] as Map<String, dynamic>?);
        themeMode = j['themeMode'] as String? ?? 'system';
        themePreset = j['themePreset'] as String? ?? 'classic';
        lastCredentialChoice = j['lastCredentialChoice'] as int?;
      }
    } catch (_) {
      // 读取失败不阻塞启动
    }
  }

  Future<void> save() async {
    try {
      _file ??= File(
          '${(await getApplicationSupportDirectory()).path}/settings.json');
      await _file!.writeAsString(jsonEncode({
        'proxy': proxy?.toJson(),
        'themeMode': themeMode,
        'themePreset': themePreset,
        'lastCredentialChoice': lastCredentialChoice,
      }));
    } catch (_) {}
  }

  /// 设置主题亮度并持久化 + 通知监听者（全局主题即时切换）。
  Future<void> setThemeMode(String mode) async {
    themeMode = mode;
    notifyListeners();
    await save();
  }

  /// 设置主题预设（原版 / Telegram X）并持久化（全局主题即时切换）。
  Future<void> setThemePreset(String preset) async {
    themePreset = preset;
    notifyListeners();
    await save();
  }

  /// 设置代理并持久化（实际下发到 TDLib 由调用方负责）。
  Future<void> setProxy(ProxyConfig? cfg) async {
    proxy = cfg;
    await save();
  }
}

/// 全局设置单例。
final settings = SettingsStore.instance;
