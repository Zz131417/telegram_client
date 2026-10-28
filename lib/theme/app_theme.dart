import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// 主题预设：原版 Telegram（默认）与 Telegram X（蓝气泡风格）。
enum ThemePreset {
  /// 原版 Telegram：灰底气泡、3390EC 主色、列表带分隔线、标准间距。
  classic,

  /// Telegram X：蓝底气泡、0088CC 主色，深色模式用蓝气泡；列表无分隔线、
  /// 更紧凑、未读标题加粗、圆角更大、卡片化更明显。
  x,
}

extension ThemePresetX on ThemePreset {
  String get label => switch (this) {
        ThemePreset.classic => '原版',
        ThemePreset.x => 'Telegram X',
      };
}

/// 布局参数：随主题预设变化，控制「界面布局」而非配色。
/// 配色走 ColorScheme / ChatTheme，布局走这里。
class AppLayout extends ThemeExtension<AppLayout> {
  const AppLayout({
    required this.bubbleRadius,
    required this.avatarRadius,
    required this.listTileVerticalPadding,
    required this.cardRadius,
    required this.inputBarRadius,
    required this.ownBubbleSolid,
    required this.showDividers,
    required this.unreadTitleBold,
    required this.unreadPreviewAccent,
    required this.appBarElevation,
  });

  /// 气泡圆角。
  final double bubbleRadius;
  /// 头像半径（列表项）。
  final double avatarRadius;
  /// 列表项上下内边距。
  final double listTileVerticalPadding;
  /// 卡片圆角。
  final double cardRadius;
  /// 底部输入条圆角。
  final double inputBarRadius;
  /// 自己发的消息是否用主色实心气泡（X 风格）。
  final bool ownBubbleSolid;
  /// 聊天列表是否显示分隔线（X 不显示）。
  final bool showDividers;
  /// 未读会话标题是否加粗（X 风格）。
  final bool unreadTitleBold;
  /// 未读会话预览文字是否用主色强调（X 风格）。
  final bool unreadPreviewAccent;
  /// AppBar 高度阴影。
  final double appBarElevation;

  static AppLayout forPreset(ThemePreset preset) => switch (preset) {
        ThemePreset.classic => const AppLayout(
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
          ),
        ThemePreset.x => const AppLayout(
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
          ),
      };

  @override
  AppLayout copyWith({
    double? bubbleRadius,
    double? avatarRadius,
    double? listTileVerticalPadding,
    double? cardRadius,
    double? inputBarRadius,
    bool? ownBubbleSolid,
    bool? showDividers,
    bool? unreadTitleBold,
    bool? unreadPreviewAccent,
    double? appBarElevation,
  }) =>
      AppLayout(
        bubbleRadius: bubbleRadius ?? this.bubbleRadius,
        avatarRadius: avatarRadius ?? this.avatarRadius,
        listTileVerticalPadding:
            listTileVerticalPadding ?? this.listTileVerticalPadding,
        cardRadius: cardRadius ?? this.cardRadius,
        inputBarRadius: inputBarRadius ?? this.inputBarRadius,
        ownBubbleSolid: ownBubbleSolid ?? this.ownBubbleSolid,
        showDividers: showDividers ?? this.showDividers,
        unreadTitleBold: unreadTitleBold ?? this.unreadTitleBold,
        unreadPreviewAccent: unreadPreviewAccent ?? this.unreadPreviewAccent,
        appBarElevation: appBarElevation ?? this.appBarElevation,
      );

  @override
  AppLayout lerp(ThemeExtension<AppLayout>? other, double t) {
    if (other is! AppLayout) return this;
    return AppLayout(
      bubbleRadius: bubbleRadius,
      avatarRadius: avatarRadius,
      listTileVerticalPadding: listTileVerticalPadding,
      cardRadius: cardRadius,
      inputBarRadius: inputBarRadius,
      ownBubbleSolid: ownBubbleSolid,
      showDividers: showDividers,
      unreadTitleBold: unreadTitleBold,
      unreadPreviewAccent: unreadPreviewAccent,
      appBarElevation: appBarElevation,
    );
  }
}

extension AppLayoutX on BuildContext {
  AppLayout get layout => Theme.of(this).extension<AppLayout>()!;
}

/// 全局主题工厂：按预设 + 亮度生成 [ThemeData]（含配色与布局）。
class AppTheme {
  static ThemeData build(ThemePreset preset, Brightness brightness) {
    final layout = AppLayout.forPreset(preset);
    switch (preset) {
      case ThemePreset.classic:
        return brightness == Brightness.light
            ? _classicLight(layout)
            : _classicDark(layout);
      case ThemePreset.x:
        return brightness == Brightness.light
            ? _xLight(layout)
            : _xDark(layout);
    }
  }

  // ---- 原版 Telegram ----
  static ThemeData _classicLight(AppLayout layout) => _base(
        brightness: Brightness.light,
        primary: const Color(0xFF3390EC),
        scaffold: const Color(0xFFF6F7F9),
        surface: Colors.white,
        bubble: const Color(0xFFEEF4FB),
        onBubble: const Color(0xFF1C2733),
        hint: Colors.black54,
        layout: layout,
      );

  static ThemeData _classicDark(AppLayout layout) => _base(
        brightness: Brightness.dark,
        primary: const Color(0xFF5EB5F7),
        scaffold: const Color(0xFF0E1621),
        surface: const Color(0xFF17212B),
        bubble: const Color(0xFF1F2C3A),
        onBubble: const Color(0xFFE9EDF2),
        hint: Colors.white60,
        layout: layout,
      );

  // ---- Telegram X ----
  // 特征：0088CC 主色 + 蓝底气泡（深/浅均如此）。
  static ThemeData _xLight(AppLayout layout) => _base(
        brightness: Brightness.light,
        primary: const Color(0xFF0088CC),
        scaffold: const Color(0xFFF4F4F4),
        surface: Colors.white,
        bubble: const Color(0xFFE6F2FB),
        onBubble: const Color(0xFF223843),
        hint: Colors.black54,
        layout: layout,
      );

  static ThemeData _xDark(AppLayout layout) => _base(
        brightness: Brightness.dark,
        primary: const Color(0xFF64B5F7),
        scaffold: const Color(0xFF0F0F0F),
        surface: const Color(0xFF17212B),
        bubble: const Color(0xFF2B5278),
        onBubble: const Color(0xFFE9EDF2),
        hint: Colors.white60,
        layout: layout,
      );

  static ThemeData _base({
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
        contentPadding:
            EdgeInsets.symmetric(horizontal: 16, vertical: layout.listTileVerticalPadding * 0.6),
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
        style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius))),
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
