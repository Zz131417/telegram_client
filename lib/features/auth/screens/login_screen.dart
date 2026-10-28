import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../config/credentials.dart';
import '../../../core/logger.dart';
import '../../../routes/transitions.dart';
import '../../../services/auth_state.dart';
import '../../../services/td_lib_service.dart';
import '../../../services/td_service.dart';
import '../../../services/service_notifier.dart';
import '../../chat/screens/chats_screen.dart';

/// 登录页（真实接入）：先让用户选择凭据来源，再按 TDLib 授权状态机切换步骤
/// 手机号 → 验证码 → 两步密码 → 就绪。
///
/// 凭据来源（按运行平台预置不同官方/关联凭据，均可在 my.telegram.org 自查）：
///  - Android      → 官方 Telegram Android   (api_id 4)
///  - 桌面端       → 官方 Telegram Desktop   (api_id 2040)
///  - iOS          → 在 官方 Telegram Android(4) 与 Telegram X(21724) 间选择
///  - 自己输入：用户填入自己的 api_id / api_hash（推荐，避免共用一组导致限流/封号）。
///  - 仅预览：不登录，直接走 Mock 数据预览完整 UI 与过渡动画。
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _customId = TextEditingController();
  final _customHash = TextEditingController();

  /// 凭据选择阶段 / 授权阶段。
  bool _choosing = true;
  bool _enteringCustom = false;

  AuthState _step = AuthState.initial;
  String? _error;
  bool _navigated = false;
  StreamSubscription<AuthEvent>? _sub;

  @override
  void dispose() {
    _sub?.cancel();
    _phone.dispose();
    _code.dispose();
    _password.dispose();
    _customId.dispose();
    _customHash.dispose();
    super.dispose();
  }

  /// 选定凭据后激活对应服务：替换为真实 TDLib（或 Mock 预览），订阅事件并 init。
  void _activate(TdService svc) {
    _sub?.cancel();
    log.i('Login', '激活服务: ${svc.runtimeType}');
    context.read<ServiceNotifier>().service = svc;
    _sub = svc.authEvents.listen(_onAuth);
    svc.init();
    if (mounted) setState(() => _choosing = false);
  }

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  /// 非 iOS 平台：按平台自动选官方预设（Android→4，桌面→2040）。
  void _useOfficialAuto() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      Credentials.useAndroid();
    } else {
      Credentials.useDesktop();
    }
    _activate(TdLibServiceImpl());
  }

  /// iOS：官方 Telegram Android (4)。
  void _useOfficialAndroid() {
    Credentials.useAndroid();
    _activate(TdLibServiceImpl());
  }

  /// iOS：官方 Telegram X (21724)。
  void _useOfficialIosX() {
    Credentials.useIosX();
    _activate(TdLibServiceImpl());
  }

  void _useCustom() {
    final id = int.tryParse(_customId.text.trim());
    if (id == null || id <= 0) {
      setState(() => _error = 'api_id 必须是正整数');
      log.w('Login', '自定义凭据校验失败: api_id 非法');
      return;
    }
    if (_customHash.text.trim().isEmpty) {
      setState(() => _error = '请填写 api_hash');
      log.w('Login', '自定义凭据校验失败: api_hash 为空');
      return;
    }
    Credentials.setCustom(id, _customHash.text);
    _activate(TdLibServiceImpl());
  }

  void _usePreview() => _activate(MockTdService());

  void _onAuth(AuthEvent e) {
    if (!mounted) return;
    log.i('Login', '授权事件 -> ${e.state}${e.message != null ? ' (${e.message})' : ''}');
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
    log.d('Login', '提交手机号');
    await context.read<ServiceNotifier>().service.setPhoneNumber(v);
  }

  Future<void> _submitCode() async {
    final v = _code.text.trim();
    if (v.isEmpty) return;
    setState(() => _error = null);
    await context.read<ServiceNotifier>().service.submitCode(v);
  }

  Future<void> _submitPassword() async {
    final v = _password.text.trim();
    if (v.isEmpty) return;
    setState(() => _error = null);
    await context.read<ServiceNotifier>().service.submitPassword(v);
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
              if (_choosing)
                _buildChoice(theme)
              else
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

  Widget _buildChoice(ThemeData theme) {
    if (_enteringCustom) {
      return Column(
        children: [
          TextField(
            controller: _customId,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'api_id（如 94575）'),
          ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 12),
          TextField(
            controller: _customHash,
            decoration: const InputDecoration(hintText: 'api_hash'),
          ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _useCustom,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('使用我的凭据', style: TextStyle(fontSize: 16)),
            ),
          ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.2, end: 0),
          TextButton(
            onPressed: () => setState(() => _enteringCustom = false),
            child: const Text('返回'),
          ),
        ],
      );
    }
    final ios = _isIOS;
    return Column(
      children: [
        if (ios) ...[
          _officialButton(theme, '官方凭据 · Android (4)', _useOfficialAndroid),
          const SizedBox(height: 12),
          _officialButton(theme, '官方凭据 · Telegram X (21724)', _useOfficialIosX),
        ] else
          _officialButton(theme, _officialLabel(), _useOfficialAuto),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () => setState(() => _enteringCustom = true),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('自己输入凭据', style: TextStyle(fontSize: 16)),
          ),
        ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _usePreview,
          child: const Text('仅预览 UI（不登录）'),
        ),
      ],
    );
  }

  /// 非 iOS 官方按钮文案：随平台显示对应客户端与 api_id。
  String _officialLabel() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return '官方凭据 · Telegram Android (4)';
    }
    return '官方凭据 · Telegram Desktop (2040)';
  }

  Widget _officialButton(ThemeData theme, String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.2, end: 0);
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
