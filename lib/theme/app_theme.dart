import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// 全局主题：Telegram 蓝为主色，圆角 + 柔和阴影，亮/暗双主题。
class AppTheme {
  static const Color telegramBlue = Color(0xFF3390EC);
  static const Color telegramBlueDark = Color(0xFF5EB5F7);
  static const Color sentBubble = Color(0xFFEEF4FB);
  static const Color sentBubbleDark = Color(0xFF1F2C3A);

  static ThemeData light() => _base(
        brightness: Brightness.light,
        scaffold: const Color(0xFFF6F7F9),
        surface: Colors.white,
        primary: telegramBlue,
        bubble: sentBubble,
        onBubble: const Color(0xFF1C2733),
        hint: Colors.black54,
      );

  static ThemeData dark() => _base(
        brightness: Brightness.dark,
        scaffold: const Color(0xFF0E1621),
        surface: const Color(0xFF17212B),
        primary: telegramBlueDark,
        bubble: sentBubbleDark,
        onBubble: const Color(0xFFE9EDF2),
        hint: Colors.white60,
      );

  static ThemeData _base({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color primary,
    required Color bubble,
    required Color onBubble,
    required Color hint,
  }) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.white,
      secondary: primary,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: brightness == Brightness.light
          ? const Color(0xFF1C2733)
          : const Color(0xFFE9EDF2),
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
