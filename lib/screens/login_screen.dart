import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../routes/transitions.dart';
import 'chats_screen.dart';

/// 登录页（UI 原型）：logo 渐入、表单上滑进场、按钮带按压反馈。
/// 真实接入时把「登录」按钮接到 TdService 的手机号/验证码流程。
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: const Icon(Icons.telegram, size: 56, color: Colors.white),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    duration: 420.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(),
              const SizedBox(height: 28),
              Text(
                'Telegram',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              )
                  .animate()
                  .fadeIn(delay: 120.ms, duration: 300.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 8),
              Text(
                '登录以开始聊天',
                style: TextStyle(color: theme.hintColor, fontSize: 15),
              )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 300.ms),
              const SizedBox(height: 36),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '手机号',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              )
                  .animate()
                  .fadeIn(delay: 280.ms, duration: 300.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () {
                    // 原型：直接进入聊天列表。真实流程替换为 TDLib 验证码步骤。
                    Navigator.of(context).pushAndRemoveUntil(
                      SlidePageRoute(page: const ChatsScreen()),
                      (_) => false,
                    );
                  },
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('登录', style: TextStyle(fontSize: 16)),
                ),
              )
                  .animate()
                  .fadeIn(delay: 360.ms, duration: 300.ms)
                  .slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
