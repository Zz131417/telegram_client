import 'package:flutter/material.dart';

import '../builder.dart';
import '../theme_module.dart';

/// 原版 Telegram 皮肤：灰底气泡、3390EC 主色、列表带分隔线、标准间距。
class ClassicTelegramModule implements AppThemeModule {
  const ClassicTelegramModule();

  @override
  String get id => 'classic';

  @override
  String get label => '原版';

  static const AppLayout _layout = AppLayout(
    bubbleRadius: 16,
    avatarRadius: 27,
    listTileVerticalPadding: 9,
    cardRadius: 16,
    inputBarRadius: 26,
    ownBubbleSolid: false,
    showDividers: true,
    unreadTitleBold: false,
    unreadPreviewAccent: false,
    appBarElevation: 0,
  );

  @override
  AppLayout layout(Brightness brightness) => _layout;

  @override
  ThemeData theme(Brightness brightness) {
    if (brightness == Brightness.light) {
      return buildBaseTheme(
        brightness: brightness,
        primary: const Color(0xFF3390EC),
        scaffold: const Color(0xFFF6F7F9),
        surface: Colors.white,
        bubble: const Color(0xFFEEF4FB),
        onBubble: const Color(0xFF1C2733),
        hint: Colors.black54,
        layout: _layout,
      );
    }
    return buildBaseTheme(
      brightness: brightness,
      primary: const Color(0xFF5EB5F7),
      scaffold: const Color(0xFF0E1621),
      surface: const Color(0xFF17212B),
      bubble: const Color(0xFF1F2C3A),
      onBubble: const Color(0xFFE9EDF2),
      hint: Colors.white60,
      layout: _layout,
    );
  }
}
