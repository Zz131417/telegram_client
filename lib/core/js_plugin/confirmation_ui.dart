import 'package:flutter/material.dart';

import 'confirmation_gateway.dart';
import 'td_risk.dart';

/// 基于 Flutter 弹窗的确认网关：高危操作向用户弹出 AlertDialog。
///
/// 需在 App 启动时用全局 [NavigatorState] 初始化：
/// ```dart
/// confirmationGateway = UiConfirmationGateway(navigatorKey);
/// ```
class UiConfirmationGateway implements ConfirmationGateway {
  UiConfirmationGateway(this.navigatorKey);

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Future<bool> requestConfirmation(PluginActionRequest req) async {
    final context = navigatorKey.currentContext;
    if (context == null) {
      // 没有可用的界面上下文，退回拒绝（安全优先）。
      return false;
    }
    final danger = req.risk == RiskLevel.danger;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(danger ? Icons.warning_amber_rounded : Icons.help_outline),
        title: Text(danger ? '高危操作确认' : '插件请求执行操作'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('插件「${req.pluginName}」想要执行：'),
            const SizedBox(height: 8),
            Text(
              req.description,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              danger
                  ? '此操作可能不可恢复，请确认你信任该插件。'
                  : '是否允许本次操作？',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('拒绝'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(danger ? '仍然执行' : '允许'),
          ),
        ],
      ),
    );
    return result == true;
  }
}
