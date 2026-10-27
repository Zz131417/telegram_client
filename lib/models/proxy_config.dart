import 'dart:convert';

/// 代理类型。
enum ProxyType { socks5, mtproto }

/// 代理配置（SOCKS5 / MTProto）。纯数据，可序列化，便于导入导出与持久化。
class ProxyConfig {
  const ProxyConfig({
    required this.type,
    required this.server,
    required this.port,
    this.username = '',
    this.password = '',
  });

  final ProxyType type;
  final String server;
  final int port;
  final String username;
  final String password;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'server': server,
        'port': port,
        'username': username,
        'password': password,
      };

  factory ProxyConfig.fromJson(Map<String, dynamic> j) => ProxyConfig(
        type: ProxyType.values.firstWhere(
          (e) => e.name == j['type'],
          orElse: () => ProxyType.socks5,
        ),
        server: j['server'] ?? '',
        port: j['port'] ?? 0,
        username: j['username'] ?? '',
        password: j['password'] ?? '',
      );

  static ProxyConfig? fromJsonOrNull(Map<String, dynamic>? j) =>
      j == null ? null : ProxyConfig.fromJson(j);

  String get typeLabel => type == ProxyType.socks5 ? 'SOCKS5' : 'MTProto';

  @override
  String toString() => '$typeLabel $server:$port';
}
