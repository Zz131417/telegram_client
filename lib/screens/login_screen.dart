import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../routes/transitions.dart';
import '../services/auth_state.dart';
import '../services/td_service.dart';
import 'chats_screen.dart';

/// 登录页（真实接入）：根据 TDLib 授权状态机切换步骤
/// 手机号 → 验证码 → 两步密码 → 就绪。
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();

  AuthState _step = AuthState.initial;
  String? _error;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    final sv = context.read<TdService>();
    sv.authEvents.listen(_onAuth);
    sv.init();
  }

  void _onAuth(AuthEvent e) {
    if (!mounted) return;
    setState(() {
      _step = e.state;
      _error = e.state == AuthState.error ? e.message : null;
    });
    if (e.state == AuthState.ready && !_navigated) {
      _navigated = true;
      Navigator.of(context).pushAndRemoveUntil(
        SlidePageRoute(page: const ChatsScreen()),
        (_) => false,
      );
    }
  }

  Future<void> _submitPhone() async {
    final v = _phone.text.trim();
    if (v.isEmpty) return;
    setState(() => _error = null);
    await context.read<TdService>().setPhoneNumber(v);
  }

  Future<void> _submitCode() async {
    final v = _code.text.trim();
    if (v.isEmpty) return;
    setState(() => _error = null);
    await context.read<TdService>().submitCode(v);
  }

  Future<void> _submitPassword() async {
    final v = _password.text.trim();
    if (v.isEmpty) return;
    setState(() => _error = null);
    await context.read<TdService>().submitPassword(v);
  }

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
                    end: const Offset(1.0, 1.0),
                    duration: 420.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(),
              const SizedBox(height: 28),
              Text(
                'Telegram',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              )
                  .animate()
                  .fadeIn(delay: 120.ms, duration: 300.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 36),
              _buildStep(theme),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(ThemeData theme) {
    switch (_step) {
      case AuthState.waitPassword:
        return _field(
          theme,
          controller: _password,
          hint: '两步验证密码',
          obscure: true,
          onTap: _submitPassword,
          label: '确认',
        );
      case AuthState.waitCode:
        return _field(
          theme,
          controller: _code,
          hint: '验证码',
          keyboard: TextInputType.number,
          onTap: _submitCode,
          label: '验证',
        );
      case AuthState.waitPhoneNumber:
      case AuthState.initial:
      default:
        return _field(
          theme,
          controller: _phone,
          hint: '手机号（含国家码，如 +86...）',
          keyboard: TextInputType.phone,
          onTap: _submitPhone,
          label: '登录',
        );
    }
  }

  Widget _field(
    ThemeData theme, {
    required TextEditingController controller,
    required String hint,
    required VoidCallback onTap,
    required String label,
    bool obscure = false,
    TextInputType? keyboard,
  }) {
    return Column(
      children: [
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          decoration: InputDecoration(hintText: hint),
        )
            .animate()
            .fadeIn(duration: 280.ms)
            .slideY(begin: 0.2, end: 0),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: onTap,
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(label, style: const TextStyle(fontSize: 16)),
          ),
        ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }
}
