/// 你的 Telegram 凭据。从 secrets_example.dart 复制而来。
/// 请填入真实值后，应用才能登录真实账号。
class Secrets {
  static const int apiId = 0;
  static const String apiHash = '';

  static bool get isConfigured => apiId != 0 && apiHash.isNotEmpty;
}
