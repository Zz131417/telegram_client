# Telegram Client (Flutter)

一个用 Flutter 从零编写的 Telegram 客户端，强调流畅的界面过渡与美观的视觉体验。
基于官方开源的 [TDLib](https://core.telegram.org/tdlib)（Telegram Database Library），
通过社区标准 Dart 封装 [`tdlib2`](https://pub.dev/packages/tdlib2) 接入——它在构建时
自动拉取并打包各平台原生 `libtdjson`，无需手动放置原生库。

> 本项目为个人/学习用途的非官方客户端。使用需遵守 Telegram 服务条款与 API 限制。

## 特性

- 🎨 流畅的页面过渡（自定义滑入/淡入、Hero 头像衔接、列表错峰进场）
- 💬 聊天气泡进出场动画、已读回执、未读角标
- 📨 **真实登录 / 收发消息**：手机号 → 验证码 → 两步密码 → 就绪；实时增量更新会话列表
- 🌗 亮 / 暗双主题（Material 3，随系统切换）
- 🧩 数据源抽象（`TdService`），UI 与 TDLib 解耦；未配置凭据时自动回退 Mock 预览
- ⚙️ CI 自动构建 Android / Linux / Windows（`build.yml`）

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

### 3. 原生库（自动）
`tdlib2` 在 `flutter pub get` 阶段通过 native-asset hook 自动下载并打包对应平台的
`libtdjson`，无需手动放置。如需强制从源码编译，见 `tdlib2` 包文档。

### 4. 运行
```bash
flutter pub get
flutter run
```
登录页依次输入：**手机号 → 验证码 → （若有）两步密码**，即可进入聊天列表，
收发消息会通过 `updateNewMessage` 实时刷新。

## CI 自动构建

`.github/workflows/build.yml` 在 GitHub Actions 上构建 **Android / Linux / Windows**
（unsigned 产物作为 artifact 上传）。触发方式：push 到 `main` 或手动 `workflow_dispatch`。

- **macOS / iOS 故意不在此工作流中构建**：两者都需要 macOS runner 与 Apple 签名，
  为把免费 macOS 额度留给 fork 所有者，这里只构建非 Apple 平台。fork 后可在文件底部
  的模板里把 `macos` / `ios` job 启用即可。
- 构建出的二进制含占位凭据，能编译运行；登录需在本地填真实 `api_id` / `apiHash`。

## 关于 `tdlib2` 包版本
`td_lib_service.dart` 中的类型与调用基于 `tdlib2` 的常见 API 形态。若你
`flutter pub get` 后该文件出现类型/字段不匹配，通常只需在此单文件内按所用版本微调，
UI 与 Provider 不受影响。

## 许可证

[MIT](LICENSE)
