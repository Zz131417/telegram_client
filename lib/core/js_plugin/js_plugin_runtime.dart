import '../../services/td_service.dart';
import 'js_bridge.dart';
import 'plugin_package.dart';

/// 一个 JS 插件（脚本 + 元信息）。
class JsPlugin {
  const JsPlugin({
    required this.id,
    required this.name,
    required this.source,
  });

  final String id;
  final String name;
  final String source;

  /// 从解析后的插件包构造（入口脚本即包的 entryScript）。
  factory JsPlugin.fromPackage(PluginPackage pkg) => JsPlugin(
        id: pkg.manifest.id,
        name: pkg.manifest.name,
        source: pkg.entryScript,
      );
}

/// 运行单个 JS 插件的运行时：持有独立 QuickJS 引擎，隔离执行。
class JsPluginRunner {
  JsPluginRunner(this.plugin, this.service);

  final JsPlugin plugin;
  final TdService service;
  JsBridge? _bridge;

  /// 从插件包直接构造 runner。
  factory JsPluginRunner.fromPackage(PluginPackage pkg, TdService service) =>
      JsPluginRunner(JsPlugin.fromPackage(pkg), service);

  /// 启动插件：初始化引擎并运行入口脚本。
  Future<void> start() async {
    _bridge?.dispose();
    _bridge = JsBridge(
      service: service,
      pluginId: plugin.id,
      pluginName: plugin.name,
    );
    await _bridge!.init();
    await _bridge!.run(plugin.source);
  }

  Future<void> stop() async {
    await _bridge?.dispose();
    _bridge = null;
  }
}

/// 示例插件：收到新消息时，向同一聊天自动回复一句固定文案。
/// 演示了 `td.onUpdate` + `td.send` 的闭环，以及高危操作会走确认流程。
const String examplePluginSource = r'''
td.onUpdate(function (u) {
  if (u['@type'] === 'updateNewMessage') {
    var msg = u['message'];
    // 避免自回复循环
    if (msg && msg['is_outgoing'] !== true) {
      td.send({
        '@type': 'sendMessage',
        chat_id: msg['chat_id'],
        input_message_content: {
          '@type': 'inputMessageText',
          text: { '@type': 'formattedText', text: '（自动回复）我收到啦 🤖' },
        },
      }).catch(function (e) {
        console.log('auto-reply failed: ' + e);
      });
    }
  }
});
console.log('auto-reply plugin loaded');
''';
