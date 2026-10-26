/// 登录时使用的 Telegram 凭据。运行时可切换，不写死进源码。
///
/// 内置「官方」凭据为仓库默认提供的预设值；用户也可在登录界面自行输入自己的
/// api_id / api_hash（推荐，避免与他人共用同一组导致限流 / 封号）。
class Credentials {
  /// 内置预设凭据（仓库默认提供）。
  static const int builtInApiId = 94575;
  static const String builtInApiHash = 'a3406de8d171bb422bb6ddf3bbd800e2';

  static int? apiId;
  static String? apiHash;

  static bool get hasValue =>
      apiId != null && (apiHash?.isNotEmpty ?? false);

  /// 使用内置预设凭据。
  static void useBuiltIn() {
    apiId = builtInApiId;
    apiHash = builtInApiHash;
  }

  /// 使用用户自行输入的凭据。
  static void setCustom(int id, String hash) {
    apiId = id;
    apiHash = hash.trim();
  }

  static void clear() {
    apiId = null;
    apiHash = null;
  }
}
