/// Telegram 应用凭据模板。
///
/// 1. 到 https://my.telegram.org/apps 创建应用，拿到 api_id / api_hash
/// 2. 复制本文件为 `secrets.dart`：  cp secrets_example.dart secrets.dart
/// 3. 填入真实值
///
/// 注意：`secrets.dart` 会被提交（含你的凭据），请勿泄露或用于他处。
class Secrets {
  static const int apiId = 0;
  static const String apiHash = '';

  static bool get isConfigured => apiId != 0 && apiHash.isNotEmpty;
}
