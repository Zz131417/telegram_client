import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'core/logger.dart';
import 'core/plugin_manager.dart';
import 'core/settings_store.dart';
import 'theme/app_theme.dart';
import 'providers/chats_provider.dart';
import 'services/td_service.dart';
import 'services/td_lib_service.dart';
import 'services/service_notifier.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 非 release 模式记更详细的日志；release 模式只留 info 及以上。
  log.minLevel =
      const bool.fromEnvironment('dart.vm.product') ? LogLevel.info : LogLevel.debug;

  // 把日志同时写入应用私有目录下的文件（移动 / 桌面可用；Web 自动跳过）。
  try {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/logs/app.log');
    await file.parent.create(recursive: true);
    await log.attachFile(file);
  } catch (e) {
    log.w('App', '无法挂载日志文件（忽略）: $e');
  }

  // 加载持久化设置与插件状态。
  await settings.load();
  await plugins.load();

  log.i('App', 'Telegram client 启动');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 默认提供 Mock 预览服务；登录界面在用户选择凭据后替换为真实 TDLib 客户端，
    // 通过 ServiceNotifier 通知 ChatsProvider 重建。
    final notifier = ServiceNotifier(MockTdService());

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsStore>.value(value: settings),
        ChangeNotifierProvider<ServiceNotifier>.value(value: notifier),
        ChangeNotifierProxyProvider<ServiceNotifier, ChatsProvider>(
          create: (c) => ChatsProvider(c.read<ServiceNotifier>().service),
          update: (_, n, p) {
            if (p != null && p.service == n.service) return p;
            p?.dispose();
            return ChatsProvider(n.service);
          },
        ),
      ],
      child: const _ThemedApp(),
    );
  }
}

/// 监听 [SettingsStore] 以即时切换主题。
class _ThemedApp extends StatelessWidget {
  const _ThemedApp();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<SettingsStore>().themeMode;
    return MaterialApp(
      title: 'Telegram',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode == 'light'
          ? ThemeMode.light
          : themeMode == 'dark'
              ? ThemeMode.dark
              : ThemeMode.system,
      home: const LoginScreen(),
    );
  }
}
