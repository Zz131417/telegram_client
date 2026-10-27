import 'dart:async';

import 'package:flutter_qjs_next/flutter_qjs.dart';

import '../../core/logger.dart';
import '../../services/td_service.dart';
import 'confirmation_gateway.dart';
import 'td_risk.dart';

/// 把真实 TDLib 暴露成 JS 全局对象 `td`，供插件脚本调用。
///
/// 暴露的 API：
/// ```js
/// // 发请求，返回 Promise（resolve 为 TDLib 响应）
/// const r = await td.send({ '@type': 'sendMessage', chat_id, input_message_content: {...} });
///
/// // 订阅原始 update（参数为已解析的 JS 对象）
/// td.onUpdate((u) => { if (u['@type'] === 'updateNewMessage') console.log(u); });
///
/// td.version; // '1.0'
/// ```
///
/// 安全模型：每次 `td.send` 先按 `@type` 判定风险：
/// - [RiskLevel.safe]：直接执行
/// - [RiskLevel.confirm] / [RiskLevel.danger]：经 [confirmationGateway] 向用户确认，
///   拒绝则 Promise reject
///
/// 说明：`setup.invoke` / `cb.invoke` 在 flutter_qjs 中通过 `dynamic` 调用，
/// 以兼容不同版本的导出差异。
class JsBridge {
  JsBridge({
    required this.service,
    required this.pluginId,
    required this.pluginName,
  });

  final TdService service;
  final String pluginId;
  final String pluginName;

  late final FlutterQjs _engine;
  final List<dynamic> _updateCbs = [];
  StreamSubscription<Map<String, dynamic>>? _sub;
  bool _initialized = false;

  /// 初始化引擎并注入 `td`。
  Future<void> init() async {
    if (_initialized) return;
    _engine = FlutterQjs();
    _engine.dispatch();

    // 定义 setup(send, onUpdate)，由 Dart 注入两个可调用函数。
    _engine.evaluate('''
      function __setup(send, onUpdate, plugin) {
        globalThis.td = {
          version: '1.0',
          plugin: plugin,
          send: send,
          onUpdate: function(cb) { onUpdate(cb); },
        };
      }
    ''');
    final setup = _engine.evaluate('__setup') as dynamic;
    setup.invoke([
      _dartSend,
      _dartOnUpdate,
      {'id': pluginId, 'name': pluginName},
    ]);

    _sub = service.updates.listen(_forwardUpdate);
    _initialized = true;
    log.i('JS', '插件引擎已就绪: $pluginName ($pluginId)');
  }

  /// 运行一段插件源码（顶层可调用 td）。
  Future<void> run(String source) async {
    if (!_initialized) await init();
    _engine.evaluate(source);
  }

  // ---- Dart → JS 注入函数 ----

  Future<dynamic> _dartSend(List<dynamic> args) async {
    final query = (args.isNotEmpty ? args[0] : null);
    if (query is! Map) {
      throw Exception('td.send 参数必须是对象');
    }
    final q = Map<String, dynamic>.from(query);
    final type = (q['@type'] ?? '').toString();
    final risk = TdRisk.levelOf(type);

    if (risk != RiskLevel.safe) {
      final allowed = await confirmationGateway.requestConfirmation(
        PluginActionRequest(
          pluginId: pluginId,
          pluginName: pluginName,
          type: type,
          risk: risk,
          description: TdRisk.describe(type, q),
        ),
      );
      if (!allowed) {
        throw Exception('用户拒绝了操作：$type');
      }
      log.i('JS', '用户已授权插件操作 $type（$pluginName）');
    }

    final res = await service.send(q);
    return res;
  }

  void _dartOnUpdate(List<dynamic> args) {
    if (args.isNotEmpty) {
      _updateCbs.add(args[0]);
    }
  }

  void _forwardUpdate(Map<String, dynamic> update) {
    for (final cb in _updateCbs) {
      try {
        (cb as dynamic).invoke([update]);
      } catch (e) {
        log.w('JS', 'onUpdate 回调异常: $e');
      }
    }
  }

  /// 释放引擎。
  Future<void> dispose() async {
    _sub?.cancel();
    _updateCbs.clear();
    try {
      _engine.port.close();
      _engine.close();
    } catch (_) {
      // 引擎可能已关闭
    }
    _initialized = false;
  }
}
