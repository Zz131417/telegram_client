# Telegram Client (Flutter)

一个用 Flutter 从零编写的 Telegram 客户端，强调流畅的界面过渡与美观的视觉体验。
基于官方开源的 [TDLib](https://core.telegram.org/tdlib)（Telegram Database Library），
不直接实现 MTProto 协议，而是封装其 JSON 接口。

> 本项目为个人/学习用途的非官方客户端。使用需遵守 Telegram 服务条款与 API 限制。

## 特性

- 🎨 流畅的页面过渡（自定义滑入/淡入、Hero 头像衔接、列表错峰进场）
- 💬 聊天气泡进出场动画、已读回执、未读角标
- 🌗 亮 / 暗双主题（Material 3，随系统切换）
- 📱 跨平台：Android / iOS / Windows / macOS / Linux（接入 TDLib 后）
- 🧩 清晰的接入层，UI 与数据源解耦

## 目录结构

```
lib/
  main.dart                       入口：Provider + 主题
  theme/app_theme.dart            亮/暗主题 + ChatTheme 扩展
  routes/transitions.dart         自定义页面过渡 + 错峰列表动画
  models/                         数据模型（chat / message）
  services/
    td_service.dart               数据源抽象（含 Mock 与真实 TDLib 接入说明）
    mock_data.dart                Mock 数据（无凭据时驱动 UI）
  providers/chats_provider.dart   状态管理
  screens/                        登录 / 聊天列表 / 聊天详情
  widgets/                        聊天列表项 / 消息气泡
```

## 运行（UI 预览，无需凭据）

```bash
flutter pub get
flutter run
```

默认使用 `MockTdService`，可直接看到完整过渡与界面效果。

## 接入真实 Telegram

1. 到 https://my.telegram.org/apps 创建应用，拿到 `api_id` / `api_hash`
2. 在 `pubspec.yaml` 启用 `tdlib`（或 `dart_tdlib`）依赖
3. 在 `services/td_service.dart` 实现 `TdLibServiceImpl`：
   - `setTdlibParameters(apiId, apiHash, databaseDirectory, encryptionKey)`
   - 监听 `authorizationStateWaitPhoneNumber → 验证码 → ready`
   - 用 `getChats` / `getChatHistory` 替换 `loadChats` / `loadMessages`
   - 把 `updateNewMessage` 推送进 `ChatsProvider`
4. 各平台放置原生 `libtdjson`（Android `.so`、iOS/macOS `.dylib`、Windows `.dll`、Linux `.so`）
5. 在 `main.dart` 将 `MockTdService()` 换成真实实现

UI 层无需改动。

## 许可证

[MIT](LICENSE)
