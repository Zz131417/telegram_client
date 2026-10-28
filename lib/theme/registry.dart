import 'package:flutter/material.dart';

import 'builder.dart';
import 'presets/classic.dart';
import 'presets/x.dart';
import 'theme_module.dart';

/// 皮肤注册表：新增一个皮肤只需实现 [AppThemeModule] 并在此登记。
/// 组件只通过 [moduleFor] 拿到当前模块，不直接依赖具体皮肤类。
final List<AppThemeModule> themeModules = <AppThemeModule>[
  const ClassicTelegramModule(),
  const TelegramXModule(),
];

AppThemeModule moduleFor(String id) =>
    themeModules.firstWhere((m) => m.id == id, orElse: () => themeModules.first);

/// 兼容旧 [ThemePreset] 枚举的便捷构造。
enum ThemePreset { classic, x }

extension ThemePresetX on ThemePreset {
  String get id => switch (this) {
        ThemePreset.classic => 'classic',
        ThemePreset.x => 'x',
      };
  String get label => switch (this) {
        ThemePreset.classic => '原版',
        ThemePreset.x => 'Telegram X',
      };
}

/// 全局主题工厂：按预设（或模块 id）+ 亮度生成 [ThemeData]。
/// 实际工作委托给对应模块，自身不再持有配色细节。
class AppTheme {
  static ThemeData build(ThemePreset preset, Brightness brightness) =>
      moduleFor(preset.id).theme(brightness);
}
