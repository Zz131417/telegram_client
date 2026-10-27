import 'package:flutter/material.dart';

/// 关于页：应用信息、版本、协议说明。
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          const Center(
            child: CircleAvatar(
              radius: 32,
              child: Icon(Icons.telegram, size: 32),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Telegram Client',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const Center(
            child: Text('非官方第三方客户端 · 基于 TDLib'),
          ),
          const Divider(height: 32),
          const ListTile(
            leading: Icon(Icons.tag_outlined),
            title: Text('版本'),
            subtitle: Text('0.1.0'),
          ),
          const ListTile(
            leading: Icon(Icons.build_outlined),
            title: Text('框架'),
            subtitle: Text('Flutter'),
          ),
          const ListTile(
            leading: Icon(Icons.description_outlined),
            title: Text('开源协议'),
            subtitle: Text('MIT'),
          ),
          const SizedBox(height: 16),
          const Text(
            '本应用为个人 / 学习用途的非官方客户端，使用须遵守 Telegram 服务条款与 API 限制。',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
