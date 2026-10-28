import 'package:flutter/material.dart';

import '../builder.dart';
import '../theme_module.dart';

/// Telegram X 皮肤：0088CC 主色 + 蓝底气泡（深/浅均如此）；列表无分隔线、
/// 更紧凑、未读标题加粗、圆角更大、卡片化更明显。
class TelegramXModule implements AppThemeModule {
  const TelegramXModule();

  @override
  String get id => 'x';

  @override
  String get label => 'Telegram X';

  static const AppLayout _layout = AppLayout(
    bubbleRadius: 18,
    avatarRadius: 24,
    listTileVerticalPadding: 8,
    cardRadius: 18,
    inputBarRadius: 24,
    ownBubbleSolid: true,
    showDividers: false,
    unreadTitleBold: true,
    unreadPreviewAccent: true,
    appBarElevation: 0,
  );

  @override
  AppLayout layout(Brightness brightness) => _layout;

  @override
  ThemeData theme(Brightness brightness) {
    if (brightness == Brightness.light) {
      return buildBaseTheme(
        brightness: brightness,
        primary: const Color(0xFF0088CC),
        scaffold: const Color(0xFFF4F4F4),
        surface: Colors.white,
        bubble: const Color(0xFFE6F2FB),
        onBubble: const Color(0xFF223843),
        hint: Colors.black54,
        layout: _layout,
      );
    }
    return buildBaseTheme(
      brightness: brightness,
      primary: const Color(0xFF64B5F7),
      scaffold: const Color(0xFF0F0F0F),
      surface: const Color(0xFF17212B),
      bubble: const Color(0xFF2B5278),
      onBubble: const Color(0xFFE9EDF2),
      hint: Colors.white60,
      layout: _layout,
    );
  }
}
