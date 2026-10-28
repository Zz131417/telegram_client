import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'theme_module.dart';

/// 共享的 [ThemeData] 构造器：各皮肤模块调用它，仅传入自己的配色与布局参数。
/// 这样新增皮肤时不需要复制一整套 Material 主题逻辑。
ThemeData buildBaseTheme({
  required Brightness brightness,
  required Color primary,
  required Color scaffold,
  required Color surface,
  required Color bubble,
  required Color onBubble,
  required Color hint,
  required AppLayout layout,
}) {
  final onSurface =
      brightness == Brightness.light ? const Color(0xFF1C2733) : const Color(0xFFE9EDF2);
  final outline = brightness == Brightness.light
      ? Colors.black12
      : Colors.white12;
  final colorScheme = brightness == Brightness.light
      ? ColorScheme.light(
          primary: primary,
          onPrimary: Colors.white,
          secondary: primary,
          onSecondary: Colors.white,
          surface: surface,
          onSurface: onSurface,
          error: const Color(0xFFE84C3D),
          onError: Colors.white,
          outline: outline,
        )
      : ColorScheme.dark(
          primary: primary,
          onPrimary: Colors.white,
          secondary: primary,
          onSecondary: Colors.white,
          surface: surface,
          onSurface: onSurface,
          error: const Color(0xFFE84C3D),
          onError: Colors.white,
          outline: outline,
        );

  final radius = layout.cardRadius;
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
    extensions: <ThemeExtension<dynamic>>[
      ChatTheme(bubble: bubble, onBubble: onBubble, hint: hint),
      layout,
    ],
    appBarTheme: AppBarTheme(
      elevation: layout.appBarElevation,
      scrolledUnderElevation: layout.appBarElevation,
      backgroundColor: surface,
      foregroundColor: onSurface,
      centerTitle: false,
      titleSpacing: 16,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: outline),
      ),
      color: surface,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: layout.listTileVerticalPadding * 0.6,
      ),
      minLeadingWidth: 0,
    ),
    dividerTheme: DividerThemeData(
      thickness: layout.showDividers ? 1 : 0,
      space: 1,
      indent: 70,
      endIndent: 16,
      color: layout.showDividers ? outline : Colors.transparent,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      foregroundColor: Colors.white,
      backgroundColor: primary,
      shape: const CircleBorder(),
      elevation: 4,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(layout.inputBarRadius),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintStyle: TextStyle(color: hint),
    ),
  );
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
