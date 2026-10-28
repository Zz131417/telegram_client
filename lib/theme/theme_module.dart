import 'package:flutter/material.dart';

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

/// 主题模块契约：每个皮肤（原版 / Telegram X / 未来扩展）实现这一接口，
/// 完整定义自己的配色 + 布局 + 组件外观，组件只消费契约而不感知具体皮肤。
abstract class AppThemeModule {
  /// 唯一标识（持久化用），如 'classic' / 'x'。
  String get id;

  /// 显示名。
  String get label;

  /// 该模块对应的布局参数（通常不随亮度变化）。
  AppLayout layout(Brightness brightness);

  /// 生成指定亮度的 [ThemeData]。
  ThemeData theme(Brightness brightness);
}
