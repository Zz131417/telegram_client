/// 登录时使用的 Telegram 凭据。运行时可切换，不写死进源码。
///
/// 内置「官方」凭据按平台预置不同的公开 api_id（均为 Telegram 官方或强关联
/// 项目注册的共享凭据，非用户私有）：
///   - Android      → telegram-android   (api_id 4)
///   - 桌面端       → telegram-desktop   (api_id 2040)
///   - iOS          → 在 telegram-android(4) 与 telegram-x(21724) 间选择
///
/// 用户也可在登录界面自行输入自己的 api_id / api_hash（推荐，避免与他人共用
/// 同一组导致限流 / 封号）。
class Credentials {
  /// 按平台预置的官方/关联凭据。
  static const int androidApiId = 4;
  static const String androidApiHash = '014b35b6184100b085b0d0572f9b5103';

  static const int desktopApiId = 2040;
  static const String desktopApiHash = 'b18441a1ff607e10a989891a5462e627';

  static const int iosXApiId = 21724;
  static const String iosXApiHash = '3e0cb5efcd52300aec5994fdfc5bdc16';

  /// 兼容旧的默认预设（Nicegram），保留以便回溯；新逻辑不再默认使用它。
  @Deprecated('use platform-specific presets instead')
  static const int builtInApiId = 94575;
  @Deprecated('use platform-specific presets instead')
  static const String builtInApiHash = 'a3406de8d171bb422bb6ddf3bbd800e2';

  static int? apiId;
  static String? apiHash;

  static bool get hasValue =>
      apiId != null && (apiHash?.isNotEmpty ?? false);

  static void useAndroid() {
    apiId = androidApiId;
    apiHash = androidApiHash;
  }

  static void useDesktop() {
    apiId = desktopApiId;
    apiHash = desktopApiHash;
  }

  static void useIosX() {
    apiId = iosXApiId;
    apiHash = iosXApiHash;
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
