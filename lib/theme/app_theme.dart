/// 兼容层：历史代码多从 `theme/app_theme.dart` 引入主题相关符号。
/// 现主题已模块化为 [AppThemeModule] 体系，这里统一再导出，避免大面积改 import。
export 'builder.dart' show ChatTheme, ChatThemeX, buildBaseTheme;
export 'theme_module.dart' show AppLayout, AppLayoutX, AppThemeModule;
export 'registry.dart' show AppTheme, ThemePreset, ThemePresetX, themeModules, moduleFor;
