# Telegram Client (Flutter)

一个用 Flutter 从零编写的 Telegram 客户端，界面流畅、视觉美观，支持多平台。

## 这是什么

这是一个第三方的 Telegram 客户端，基于官方 Telegram 数据库库（TDLib）实现**真实的登录与消息收发**。
没有登录凭据时也能直接打开，预览完整的界面与动画效果。

> 本项目为个人 / 学习用途的非官方客户端，使用须遵守 Telegram 服务条款与 API 限制。

## 功能

- 🎨 流畅的页面过渡与聊天气泡动画
- 💬 真实登录与收发消息（手机号 → 验证码 → 两步密码）
- 🌗 亮色 / 暗色双主题，跟随系统切换
- 🔌 代理支持（SOCKS5 / MTProto），登录后生效
- 🧩 插件管理（紧凑气泡、调试日志浮窗等可启停模块）
- 📤 配置导入 / 导出（代理、主题、插件状态一键迁移）
- 📱 支持 Android、Windows、Linux、iOS、iPad，以及 Wear OS 手表

## 快速体验

```bash
flutter pub get
flutter run
```

打开后在登录页选择「官方凭据」即可登录，也可以填写自己的 api_id / api_hash，或直接点「仅预览 UI」看效果。

## 文档

- [使用指南](doc/usage.md) — 登录流程、各平台安装、代理 / 插件 / 导入导出、常见问题
- [构建与开发指南](doc/build.md) — 从源码构建、CI 产物、架构速览

## 许可证

[MIT](LICENSE)
