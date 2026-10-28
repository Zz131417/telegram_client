import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/logger.dart';
import '../../../core/settings_store.dart';
import '../../../models/proxy_config.dart';
import '../../../services/service_notifier.dart';

/// 代理设置页：配置 SOCKS5 / MTProto 代理并应用到当前 TDLib 会话。
class ProxyScreen extends StatefulWidget {
  const ProxyScreen({super.key});

  @override
  State<ProxyScreen> createState() => _ProxyScreenState();
}

class _ProxyScreenState extends State<ProxyScreen> {
  final _server = TextEditingController();
  final _port = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  ProxyType _type = ProxyType.socks5;

  @override
  void initState() {
    super.initState();
    final p = settings.proxy;
    if (p != null) {
      _type = p.type;
      _server.text = p.server;
      _port.text = p.port.toString();
      _user.text = p.username;
      _pass.text = p.password;
    }
  }

  @override
  void dispose() {
    _server.dispose();
    _port.dispose();
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final server = _server.text.trim();
    final port = int.tryParse(_port.text.trim()) ?? 0;
    if (server.isEmpty || port <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写服务器与端口')),
      );
      return;
    }
    final cfg = ProxyConfig(
      type: _type,
      server: server,
      port: port,
      username: _user.text.trim(),
      password: _pass.text,
    );
    final svc = context.read<ServiceNotifier>().service;
    await svc.setProxy(cfg);
    await settings.setProxy(cfg);
    log.i('Proxy', '已保存代理 $cfg');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('代理已保存（登录后生效）')),
      );
      Navigator.of(context).pop();
    }
  }

  Future<void> _clear() async {
    final svc = context.read<ServiceNotifier>().service;
    await svc.clearProxy();
    await settings.setProxy(null);
    log.i('Proxy', '已清除代理');
    _server.clear();
    _port.clear();
    _user.clear();
    _pass.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('代理已清除')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('代理设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<ProxyType>(
            value: _type,
            decoration: const InputDecoration(labelText: '类型'),
            items: const [
              DropdownMenuItem(value: ProxyType.socks5, child: Text('SOCKS5')),
              DropdownMenuItem(
                  value: ProxyType.mtproto, child: Text('MTProto')),
            ],
            onChanged: (v) => setState(() => _type = v ?? ProxyType.socks5),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _server,
            decoration: const InputDecoration(
                labelText: '服务器地址', hintText: '例如 127.0.0.1'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _port,
            decoration: const InputDecoration(labelText: '端口'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _user,
            decoration: const InputDecoration(labelText: '用户名（可选）'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pass,
            decoration: InputDecoration(
              labelText: _type == ProxyType.mtproto ? 'Secret（可选）' : '密码（可选）',
            ),
            obscureText: true,
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('保存并应用')),
          const SizedBox(height: 12),
          if (settings.proxy != null)
            OutlinedButton(
              onPressed: _clear,
              child: const Text('清除代理'),
            ),
          const SizedBox(height: 12),
          const Text(
            '说明：Mock 预览模式下仅保存配置；真实登录后代理会即时下发到 TDLib。',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
