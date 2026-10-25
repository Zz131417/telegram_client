import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/secrets.dart';
import 'theme/app_theme.dart';
import 'providers/chats_provider.dart';
import 'services/td_service.dart';
import 'services/td_lib_service.dart';
import 'screens/login_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 已配置凭据 -> 真实 TDLib 客户端；否则回退 Mock，UI 仍可预览。
    final TdService service =
        Secrets.isConfigured ? TdLibServiceImpl() : MockTdService();

    return MultiProvider(
      providers: [
        Provider<TdService>.value(value: service),
        ChangeNotifierProxyProvider<TdService, ChatsProvider>(
          create: (c) => ChatsProvider(c.read<TdService>()),
          update: (_, s, p) => p ?? ChatsProvider(s),
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
