# Telegram Client (Flutter)

一个用 Flutter 从零编写的 Telegram 客户端，强调流畅的界面过渡与美观的视觉体验。
基于官方开源的 [TDLib](https://core.telegram.org/tdlib)（Telegram Database Library），
不直接实现 MTProto 协议，而是封装其 JSON 接口，通过社区标准 Dart 封装
[`tdlib`](https://pub.dev/packages/tdlib) 接入。

> 本项目为个人/学习用途的非官方客户端。使用需遵守 Telegram 服务条款与 API 限制。

## 特性

- 🎨 流畅的页面过渡（自定义滑入/淡入、Hero 头像衔接、列表错峰进场）
- 💬 聊天气泡进出场动画、已读回执、未读角标
- 📨 **真实登录 / 收发消息**：手机号 → 验证码 → 两步密码 → 就绪；实时增量更新会话列表
- 🌗 亮 / 暗双主题（Material 3，随系统切换）
- 🧩 数据源抽象（`TdService`），UI 与 TDLib 解耦；未配置凭据时自动回退 Mock 预览

## 目录结构

```
lib/
  main.dart                       入口：注入 TdService + Provider + 主题
  config/secrets.dart             你的 api_id / api_hash（占位，需填真实值）
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
flutter run
```

未配置凭据时自动使用 `MockTdService`，可直接看到完整过渡与界面效果。

## 接入真实 Telegram（登录 + 收发）

### 1. 申请凭据
到 https://my.telegram.org/apps 创建应用，拿到 `api_id` / `api_hash`。

### 2. 填入凭据
```bash
cp lib/config/secrets_example.dart lib/config/secrets.dart
# 编辑 secrets.dart，填入真实 api_id / api_hash
```
应用检测到已配置后会自动启用真实 `TdLibServiceImpl`。

### 3. 放置各平台原生 libtdjson
`tdlib` 包需要运行时能加载到官方原生库：

| 平台 | 文件 | 放置位置 |
|------|------|----------|
| Android | `libtdjson.so` | `android/app/src/main/jniLibs/<abi>/` (armeabi-v7a, arm64-v8a, x86_64) |
| iOS | `libtdjson.dylib` | 链接进 Runner（Xcode 的 Frameworks） |
| macOS | `libtdjson.dylib` | `macos/Runner/Frameworks/` 或 app 包内 |
| Windows | `tdjson.dll`（及依赖如 `tdjson_private.dll`、`libcrypto`） | 与 `.exe` 同级目录 |
| Linux | `libtdjson.so` | 与可执行文件同级，或系统 lib 路径 |

预编译库可从官方 TDLib 仓库的 GitHub Release，或社区预编译包获取。

### 4. 运行
```bash
flutter pub get
flutter run
```
登录页依次输入：**手机号 → 验证码 → （若有）两步密码**，即可进入聊天列表，
收发消息会通过 `updateNewMessage` 实时刷新。

## 关于 `tdlib` 包版本
`td_lib_service.dart` 中的类型与调用基于 `tdlib` 包的常见 API 形态。若你
`flutter pub get` 后该文件出现类型/字段不匹配，通常只需在此单文件内按所用
版本微调（构造、`invoke`/`send`、`receiver` 流、字段名），UI 与 Provider 不受影响。

## 许可证

[MIT](LICENSE)
