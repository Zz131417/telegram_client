import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/chats_provider.dart';
import 'services/td_service.dart';
import 'services/td_lib_service.dart';
import 'services/service_notifier.dart';
import 'screens/login_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 默认提供 Mock 预览服务；登录界面在用户选择凭据后替换为真实 TDLib 客户端，
    // 通过 ServiceNotifier 通知 ChatsProvider 重建。
    final notifier = ServiceNotifier(MockTdService());

    return MultiProvider(
      providers: [
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
      child: MaterialApp(
        title: 'Telegram',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const LoginScreen(),
      ),
    );
  }
}
