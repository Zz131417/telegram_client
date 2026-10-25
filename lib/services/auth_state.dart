/// 登录状态机。TDLib 的 authorizationState 最终收敛成这几个 UI 步骤。
enum AuthState {
  /// 初始/未知
  initial,
  /// 需要手机号
  waitPhoneNumber,
  /// 需要验证码
  waitCode,
  /// 需要两步验证密码
  waitPassword,
  /// 已就绪（已登录）
  ready,
  /// 登出中
  loggingOut,
  /// 出错
  error,
}

/// 一次登录状态变化事件，可能携带提示/错误信息。
class AuthEvent {
  const AuthEvent(this.state, {this.message});
  final AuthState state;
  final String? message;

  @override
  String toString() => 'AuthEvent($state${message != null ? ": $message" : ""})';
}
