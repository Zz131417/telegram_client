import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// 主题预设：原版 Telegram（默认）与 Telegram X（蓝气泡风格）。
enum ThemePreset {
  /// 原版 Telegram：灰底气泡、3390EC 主色。
  classic,

  /// Telegram X：蓝底气泡、0088CC 主色，深色模式用蓝气泡。
  x,
}

extension ThemePresetX on ThemePreset {
  String get label => switch (this) {
        ThemePreset.classic => '原版',
        ThemePreset.x => 'Telegram X',
      };
}

/// 全局主题工厂：按预设 + 亮度生成 [ThemeData]。
class AppTheme {
  static ThemeData build(ThemePreset preset, Brightness brightness) {
    switch (preset) {
      case ThemePreset.classic:
        return brightness == Brightness.light ? _classicLight() : _classicDark();
      case ThemePreset.x:
        return brightness == Brightness.light ? _xLight() : _xDark();
    }
  }

  // ---- 原版 Telegram ----
  static ThemeData _classicLight() => _base(
        brightness: Brightness.light,
        primary: const Color(0xFF3390EC),
        scaffold: const Color(0xFFF6F7F9),
        surface: Colors.white,
        bubble: const Color(0xFFEEF4FB),
        onBubble: const Color(0xFF1C2733),
        hint: Colors.black54,
      );

  static ThemeData _classicDark() => _base(
        brightness: Brightness.dark,
        primary: const Color(0xFF5EB5F7),
        scaffold: const Color(0xFF0E1621),
        surface: const Color(0xFF17212B),
        bubble: const Color(0xFF1F2C3A),
        onBubble: const Color(0xFFE9EDF2),
        hint: Colors.white60,
      );

  // ---- Telegram X ----
  // 特征：0088CC 主色 + 蓝底气泡（深/浅均如此）。
  static ThemeData _xLight() => _base(
        brightness: Brightness.light,
        primary: const Color(0xFF0088CC),
        scaffold: const Color(0xFFF4F4F4),
        surface: Colors.white,
        bubble: const Color(0xFFE6F2FB),
        onBubble: const Color(0xFF223843),
        hint: Colors.black54,
      );

  static ThemeData _xDark() => _base(
        brightness: Brightness.dark,
        primary: const Color(0xFF64B5F7),
        scaffold: const Color(0xFF0F0F0F),
        surface: const Color(0xFF17212B),
        bubble: const Color(0xFF2B5278),
        onBubble: const Color(0xFFE9EDF2),
        hint: Colors.white60,
      );

  static ThemeData _base({
    required Brightness brightness,
    required Color primary,
    required Color scaffold,
    required Color surface,
    required Color bubble,
    required Color onBubble,
    required Color hint,
  }) {
    final colorScheme = brightness == Brightness.light
        ? ColorScheme.light(
            primary: primary,
            onPrimary: Colors.white,
            secondary: primary,
            onSecondary: Colors.white,
            surface: surface,
            onSurface: const Color(0xFF1C2733),
            error: const Color(0xFFE84C3D),
            onError: Colors.white,
            outline: Colors.transparent,
          )
        : ColorScheme.dark(
            primary: primary,
            onPrimary: Colors.white,
            secondary: primary,
            onSecondary: Colors.white,
            surface: surface,
            onSurface: const Color(0xFFE9EDF2),
            error: const Color(0xFFE84C3D),
            onError: Colors.white,
            outline: Colors.transparent,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        titleSpacing: 16,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: surface,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(color: hint),
      ),
      extensions: <ThemeExtension<dynamic>>[
        ChatTheme(
          bubble: bubble,
          onBubble: onBubble,
          hint: hint,
        ),
      ],
    );
  }
}

/// 聊天界面专用扩展色，避免反复写判断。
class ChatTheme extends ThemeExtension<ChatTheme> {
  const ChatTheme({
    required this.bubble,
    required this.onBubble,
    required this.hint,
  });
  final Color bubble;
  final Color onBubble;
  final Color hint;

  @override
  ChatTheme copyWith({Color? bubble, Color? onBubble, Color? hint}) => ChatTheme(
        bubble: bubble ?? this.bubble,
        onBubble: onBubble ?? this.onBubble,
        hint: hint ?? this.hint,
      );

  @override
  ChatTheme lerp(ThemeExtension<ChatTheme>? other, double t) {
    if (other is! ChatTheme) return this;
    return ChatTheme(
      bubble: Color.lerp(bubble, other.bubble, t)!,
      onBubble: Color.lerp(onBubble, other.onBubble, t)!,
      hint: Color.lerp(hint, other.hint, t)!,
    );
  }
}

extension ChatThemeX on BuildContext {
  ChatTheme get chat => Theme.of(this).extension<ChatTheme>()!;
}
