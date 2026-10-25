import 'package:flutter/material.dart';

/// 自定义页面过渡：从右滑入 + 淡入，配合 Hero 头像做无缝衔接。
/// 这是「画面过渡」的核心，比默认 Material 推栈更顺、更有层次。
class SlidePageRoute extends PageRouteBuilder {
  SlidePageRoute({required this.page, this.offset = const Offset(1, 0)})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween<Offset>(
              begin: offset,
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutExpo));
            final fade = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
            );
            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(opacity: fade, child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 260),
        );

  final Widget page;
  final Offset offset;
}

/// 淡入 + 轻微缩放，适合弹层 / 设置页。
class FadeScalePageRoute extends PageRouteBuilder {
  FadeScalePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scale = Tween<double>(begin: 0.96, end: 1).chain(
              CurveTween(curve: Curves.easeOutCubic),
            );
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation.drive(scale), child: child),
            );
          },
          transitionDuration: const Duration(milliseconds: 240),
          opaque: false,
          barrierColor: Colors.black26,
        );

  final Widget page;
}

/// 列表项进场：淡入 + 上滑，用 index 做 stagger（错峰）延迟。
class StaggeredList extends StatelessWidget {
  const StaggeredList({
    super.key,
    required this.index,
    required this.child,
    this.fromBottom = true,
  });
  final int index;
  final Widget child;
  final bool fromBottom;

  @override
  Widget build(BuildContext context) {
    final begin = fromBottom ? const Offset(0, 0.12) : const Offset(0, -0.12);
    return TweenAnimationBuilder<Offset>(
      duration: Duration(milliseconds: 360 + index * 28),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: begin, end: Offset.zero),
      builder: (context, offset, child) => Transform.translate(
        offset: Offset(0, offset.dy * 40),
        child: Opacity(
          opacity: 1 - offset.dy.abs() / 0.12,
          child: child,
        ),
      ),
      child: child,
    );
  }
}
