# Telegram Client (Flutter)

一个用 Flutter 从零编写的 Telegram 客户端，强调流畅的界面过渡与美观的视觉体验。
基于官方开源的 [TDLib](https://core.telegram.org/tdlib)（Telegram Database Library），
通过 `dart:ffi` 直接绑定官方 [`libtdjson`](https://core.telegram.org/tdlib) 的 JSON 接口，
不依赖任何第三方 TDLib Dart 封装，因此各平台 `flutter pub get` 与编译都干净通过；
原生库在运行时按需加载；CI 构建的 Android / Linux / Windows / Wear OS 已自带该库，
可直接真实登录，找不到时 App 不会崩溃（仅真实登录不可用，走 Mock 预览）。

> 本项目为个人/学习用途的非官方客户端。使用需遵守 Telegram 服务条款与 API 限制。

## 特性

- 🎨 流畅的页面过渡（自定义滑入/淡入、Hero 头像衔接、列表错峰进场）
- 💬 聊天气泡进出场动画、已读回执、未读角标
- 📨 **真实登录 / 收发消息**：手机号 → 验证码 → 两步密码 → 就绪；实时增量更新会话列表
- 🌗 亮 / 暗双主题（Material 3，随系统切换）
- 🧩 数据源抽象（`TdService`），UI 与 TDLib 解耦；未配置凭据时自动回退 Mock 预览
- 🕑 **Wear OS 支持**：智能手表 companion（圆屏适配，CI 出 arm64 APK）
- 📱 **iPad 支持**：iOS 产物为 universal 构建，iPhone 与 iPad 通用，无需额外配置
- ⚙️ CI 自动构建 Android / Linux / Windows / iOS / Wear OS（`build.yml`）

## 目录结构

```
lib/
  main.dart                       手机端入口：注入 TdService + Provider + 主题
  wear_main.dart                  手表端入口（Wear OS companion，圆屏适配）
  config/credentials.dart         凭据来源（内置预设 + 登录时自填，不写死进仓库）
  theme/app_theme.dart            亮/暗主题 + ChatTheme 扩展
  routes/transitions.dart         自定义页面过渡 + 错峰列表动画
  models/                         数据模型（chat / message）
  services/
    auth_state.dart               登录状态机（AuthState / AuthEvent）
    td_service.dart               数据源抽象 + MockTdService
    td_lib_service.dart           真实 TDLib 接入（所有第三方包耦合集中于此）
  providers/chats_provider.dart   会话列表状态 + 实时新消息订阅
  screens/                        登录 / 聊天列表 / 聊天详情
  widgets/                        聊天列表项 / 消息气泡
```

## 运行（UI 预览，无需凭据）

```bash
flutter pub get
flutter run            # 手机端（默认入口 lib/main.dart）
flutter run -t lib/wear_main.dart   # 手表端（需 Wear OS 模拟器/设备）
```

未配置凭据时自动使用 `MockTdService`，可直接看到完整过渡与界面效果。

## 接入真实 Telegram（登录 + 收发）

登录页会先让你**选择凭据来源**，无需把 api_id / api_hash 写进源码或仓库：

- **官方凭据（按平台预置）**：登录页按**运行平台**自动给出对应的官方/关联凭据，
  点一下即登录；iOS 上额外提供两个官方选项供选择：
  - Android      → 官方 **Telegram Android** (api_id 4)
  - 桌面端       → 官方 **Telegram Desktop** (api_id 2040)
  - iOS          → 官方 **Telegram Android (4)** 或 **Telegram X (21724)** 任选
  > 这些均为公开共享凭据（非你私有），多人共用可能触发限流、被 Telegram 观察甚至封号；
  > **强烈建议用自己的**（见下）。
- **自己输入**：在登录页填入你自己的 `api_id` / `api_hash`（推荐）。
  到 https://my.telegram.org/apps 创建应用，约 2 分钟免费拿到。
- **仅预览 UI**：不登录，直接走 Mock 数据预览完整界面与过渡动画。

### 原生 libtdjson（真实登录需要）
`TdLibServiceImpl` 在运行时用 `DynamicLibrary.open` 加载官方原生库。**CI 已自动把库打进包里**，
因此从 Actions 下载的 **Android / Linux / Windows / Wear OS** 产物开箱即可真实登录：

| 平台 | 文件 | CI 是否自带 | 本地自行构建时的放置位置 |
|------|------|-------------|--------------------------|
| Android | `libtdjson.so` | ✅ 自带（up9cloud 预编译 v1.8.65） | `android/app/src/main/jniLibs/<abi>/` |
| Wear OS | `libtdjson.so` | ✅ 同上（arm64-v8a） | 同上 |
| Linux | `libtdjson.so` | ✅ 自带（prebuilt-tdlib） | 与可执行文件同级目录 |
| Windows | `tdjson.dll` | ✅ 自带（prebuilt-tdlib，已静态链接 OpenSSL/zlib） | 与 `.exe` 同级目录 |
| iOS | `libtdjson.dylib` | ⚠️ 需手动 | 放进 `Runner.app/Frameworks` 并 Embed & Sign（见下） |

- **iOS（模拟器 / 未签名 IPA）**：CI 暂未打包 dylib。真机登录需在本地把为 iOS device
  编译的 `libtdjson.dylib` 加入 `Runner.app/Frameworks` 并设为 Embed & Sign；未签名包经
  AltStore / Sideloadly / ESign 侧载时会一并重签。
- 本地 `flutter run` 没放库也能启动并走 Mock 预览；真实登录会提示「加载 libtdjson 失败」。
  预编译库来源：Android/Wear → [up9cloud/android-libtdjson](https://github.com/up9cloud/android-libtdjson)，
  Linux/Windows → [AlexXanderGrib/prebuilt-tdlib](https://github.com/AlexXanderGrib/prebuilt-tdlib)（静态链接，无需额外依赖）。

### 4. 运行
```bash
flutter pub get
flutter run
```
登录页依次输入：**手机号 → 验证码 → （若有）两步密码**，即可进入聊天列表，
收发消息会通过 `updateNewMessage` 实时刷新。

## CI 自动构建

`.github/workflows/build.yml` 在 GitHub Actions 上构建
**Android / Linux(x64) / Windows / iOS(模拟器) / iOS 未签名 IPA / Wear OS(arm64)**。
真实登录用的 `libtdjson` 已随 Android / Linux / Windows / Wear OS 包自带；iOS 需手动加 dylib。
工作流在构建前会自动执行 `flutter create --platforms=...` 生成对应宿主工程，
因此仓库无需提交庞大的平台文件夹，fork 后开箱即跑。

- **Linux 只出 x64**：Flutter 官方 Linux SDK 仅 x86-64；arm64 Linux 官方未发布，
  无法用官方 SDK 在 CI 编译（如需 arm64 需自行编译或社区 SDK）。
- **iPad（默认支持）**：iOS 产物是 universal 构建，iPhone 与 iPad 通用；
  `Info.plist` 自带 iPad 方向，无需额外开关。
- **iOS 模拟器**：在 macOS runner 上构建 simulator 版（debug / 无签名），产物 `Runner.app` 可直接拖进模拟器。
- **iOS 真机 `.ipa`（未签名，默认构建）**：`build.yml` 的 `ios-ipa` job 直接跑
  （无需任何 Apple 凭据），用 `flutter build ios --release --no-codesign` 编译出未签名
  `Runner.app`，再打包成 `telegram_client-unsigned.ipa`。
  - ⚠️ 未签名包**无法直接在未越狱真机安装**（iOS 要求签名），需用 **AltStore / Sideloadly / ESign**
    这类侧载工具——它们会在安装时自动重签，正好吃未签名的 `.ipa`。
  - 模拟器版（`.app`）和真机未签名 `.ipa` 是两个独立产物，按需取用。
- **Wear OS（arm64）**：`build.yml` 的 `wear` job 单独生成 Android 宿主，在 manifest 中
  声明手表硬件特性（`required=false`，手机也能装）并把 `minSdk` 提到 30（Wear OS 4/5），
  再用 `flutter build apk --split-per-abi --target-platform android-arm64 -t lib/wear_main.dart`
  出 `wearos-arm64.apk`。`lib/wear_main.dart` 用纯 Flutter 适配小表盘（按屏幕短边判手表、给圆屏
  安全内边距），不依赖第三方 Wear 包——`wear` 包的 Android 模块在 Flutter 3.44 的 AGP 8 下因
  缺 namespace 无法编译，会拖垮所有 Android 构建，故改为纯 Flutter 实现。用手表侧载工具安装到
  Wear OS 4+ 设备即可。
- **macOS 桌面 App 故意不构建**：独立 `.app` 需要 Apple 签名，故此处只出 iOS、不出 macOS。
- 构建出的二进制含内置预设凭据，能编译运行；登录时在界面选择「官方」或输入你自己的 `api_id` / `apiHash`。

## 关于接入实现
`td_lib_service.dart` 直接用 `dart:ffi` 调用 libtdjson 的 JSON 接口（create/send/receive），
自行解析协议 JSON 到我方领域模型。所有 FFI / 协议细节都收敛在本文件与 `td_native.dart`，
UI 与 Provider 完全不感知 TDLib。若 TDLib 协议字段有出入，只需微调这两个文件。

## 许可证

[MIT](LICENSE)
