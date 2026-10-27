import '../core/logger.dart';
import 'td_risk.dart';

/// 一次待确认的插件操作。
class PluginActionRequest {
  const PluginActionRequest({
    required this.pluginId,
    required this.pluginName,
    required this.type,
    required this.risk,
    required this.description,
  });

  final String pluginId;
  final String pluginName;
  final String type; // TDLib @type
  final RiskLevel risk;
  final String description;
}

/// 高危操作确认网关。实现由宿主提供：
/// - 无 UI 环境（Mock / 后台）使用 [HeadlessDenyGateway]（默认拒绝）
/// - 真实界面使用 UI 弹窗网关（见 app 侧注入）
abstract class ConfirmationGateway {
  /// 返回 true 表示用户允许执行。
  Future<bool> requestConfirmation(PluginActionRequest req);
}

/// 默认网关：无界面时一律拒绝非安全操作（安全起见，绝不静默放行）。
class HeadlessDenyGateway implements ConfirmationGateway {
  @override
  Future<bool> requestConfirmation(PluginActionRequest req) async {
    log.w('JS', '无 UI 环境，拒绝插件高危操作 ${req.type}（${req.pluginName}）');
    return false;
  }
}

/// 全局确认网关单例。App 启动时替换为 UI 弹窗实现即可。
ConfirmationGateway confirmationGateway = HeadlessDenyGateway();
