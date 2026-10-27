# 构建与开发指南

面向想从源码构建、或参与开发的用户。

---

## 一、环境准备

- 安装 [Flutter](https://flutter.dev) 稳定版（建议 3.x）
- 准备对应平台工具链：
  - Android：Android SDK + 一个模拟器 / 真机
  - Windows：Visual Studio（含「使用 C++ 的桌面开发」）
  - Linux：GTK 3 等系统依赖
  - iOS：Xcode（仅 macOS 可构建）
- 本项目不提交平台宿主工程，首次运行会自动生成，无需手动创建

---

## 二、本地运行

```bash
flutter pub get
flutter run                       # 手机端
flutter run -t lib/wear_main.dart # 手表端（Wear OS）
```

未配置凭据时自动回退 Mock，可直接预览界面。

---

## 三、CI 自动构建与发版

CI 在 `.github/workflows/build.yml` 中定义，两种触发：

- **手动触发（`workflow_dispatch`）**：在仓库 **Actions** 页点「Run workflow」即开始构建，构建完成后自动发布 GitHub Release。
- **定时触发（`schedule`，每周一 03:00 UTC）**：仅运行 `clear-caches` job，清空所有 GitHub Actions 缓存（pub / Gradle 等），避免缓存陈旧或膨胀。

### 产物（手动构建时生成，已自带 libtdjson）
- Android（arm64 / armeabi-v7a / x86_64）
- Linux（x64）
- Windows（x64）
- iOS 模拟器（Runner.app）
- iOS 未签名 IPA（需侧载重签）
- Wear OS（arm64）

### 版本规则（状态存于仓库根 `version.json`）
- **测试版** `0.Y.0-rN`（prerelease）：每自动构建一次 `N+1`
- **正式版** `0.Y.0`（stable）：发布后下一测试周期重置为 `0.(Y+1).0-r0`
- 可在 Run workflow 时填 `version` 覆盖（填 `0.1.0` 即正式版；填 `0.2.0-r0` 即下一测试版）；不填则按 `version.json` 自动递增
- 把 `publish_release` 关掉则只出包、不发版

> libtdjson 具体版本与下载源统一维护在 [`.github/workflows/build.yml`](.github/workflows/build.yml)，升级 TDLib 时只改该文件即可。

---

## 四、架构速览

```
lib/
  main.dart / wear_main.dart       手机端 / 手表端入口
  config/credentials.dart          凭据来源（内置预设 + 登录时自填）
  core/
    logger.dart                    日志系统
    settings_store.dart            设置持久化（代理 / 主题 / 凭据偏好）
    plugin_manager.dart            插件注册与启用状态
  models/proxy_config.dart         代理配置（可序列化）
  services/
    td_service.dart                数据源抽象 + MockTdService
    td_lib_service.dart            真实 TDLib 接入（FFI 细节集中于此）
    td_native.dart                 dart:ffi 绑定
    auth_state.dart                登录状态机
  providers/chats_provider.dart    会话状态 + 实时订阅
  screens/                         界面（含登录 / 聊天 / 设置 / 代理 / 插件 / 导入导出 / 日志）
  widgets/                         组件
```

所有 TDLib / FFI 细节收敛在 `services/`，UI 与 Provider 不感知——协议字段有出入时只需微调这两处。

---

## 五、JS 插件 API

项目内置一个 QuickJS 引擎（`flutter_qjs_next`），允许第三方脚本通过 `td` 全局对象调用 TDLib。
相关代码在 `lib/core/js_plugin/`：

- `td_risk.dart`：TDLib 请求风险分级（safe / confirm / danger）
- `confirmation_gateway.dart`：确认网关抽象 + 无界面默认拒绝实现
- `confirmation_ui.dart`：基于 AlertDialog 的确认网关，高危操作弹窗询问用户
- `js_bridge.dart`：在 QuickJS 中注入 `td`（含 `send` / `onUpdate`），并做风险拦截
- `js_plugin_runtime.dart`：`JsPlugin` / `JsPluginRunner`，每个插件独立引擎隔离运行

JS 侧可用：

```js
const r = await td.send({ '@type': 'sendMessage', chat_id, input_message_content: {} });
td.onUpdate((u) => { /* 原始 update 对象 */ });
```

安全模型：每次 `td.send` 先按 `@type` 判定风险，confirm / danger 级操作经
`confirmationGateway` 向用户确认，**拒绝则请求被拒**，绝不静默执行。无 UI 环境回退为拒绝。

> 注：引入 `flutter_qjs_next` 后不再满足「零第三方依赖」；其自带原生库会在各平台 `flutter build` 时自动编入，CI 已覆盖 Android / iOS / Linux / Windows / Wear OS。
