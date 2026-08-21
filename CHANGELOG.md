# Changelog

## 2.0.0 - 2026-08-21

### 广告方案重构（重大变更）

- 移除 `gromore_ads` 第三方 Flutter 插件，直接接入官方穿山甲聚合 SDK（`com.pangle.cn:mediation-sdk:7.7.1.6`，当前最新版）。
- 自维护 Android 原生桥接（MethodChannel + PlatformView），不再依赖第三方插件事件通道。
- 开屏容器由原生侧完全掌控，广告关闭时必定移除视图，修复「黑容器残留盖住主页」问题。
- 进主页时机改为由广告关闭/加载失败驱动，并保留 6 秒超时兜底，修复开屏黑屏。
- 激励视频增加 8 秒超时保护，广告源无填充时不再卡死 UI。

### 修复

- 修复启动闪退（FileProvider 冲突，改用 pangle 自带 FileProvider）。
- 修复 Banner 模板广告在无填充时的空容器问题。

### 工程配置

- 强制锁定 `mediation-sdk:7.7.1.6`，排除冲突孤儿 artifact `mediation-auto-adapter`。
- `minSdk` 提升至 24（GroMore 要求）。
- 关闭 release 混淆（SDK fat-aar 内部缺类，官方接入常见做法）。
- 新增穿山甲私有 Maven 仓库。

## 1.1.0 - 2026-08

- 接入 GroMore（穿山甲聚合）广告：开屏 / 激励视频 / Banner。
- 新增隐私同意弹窗（同意后才初始化广告 SDK）。
- 配置真实 AppID 与广告位 ID。

## 1.0.0 - 初始版本

- 极简天气 App（Flutter 跨端）。
- 接入和风天气 API：自动定位 / 当前天气 / 逐小时 / 7 天预报 / 城市搜索切换。
- Riverpod 状态管理，本地缓存兜底。
