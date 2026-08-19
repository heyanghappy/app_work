# 极简天气 App

基于 **Flutter** 的跨端（iOS + Android）极简天气应用，接入[和风天气](https://dev.qweather.com/) API。

## 功能

- 📍 打开自动定位当前城市（授权失败时回退默认城市「北京」）
- 🌡️ 当前实时天气：温度、体感、湿度、风力
- ⏱️ 逐小时温度趋势（横向滚动）
- 📅 未来 7 天预报（温度区间条）
- 🔍 城市搜索 / 添加 / 切换（底部弹层）
- 💾 本地缓存：无网络时仍可查看上一次数据

## 快速开始

### 1. 安装 Flutter SDK

参考官方文档：https://docs.flutter.dev/get-started/install

macOS 可通过 Homebrew 安装：

```bash
brew install --cask flutter
flutter doctor   # 检查环境，按提示补齐 iOS/Android 工具链
```

### 2. 申请和风天气 Key

1. 注册并登录 https://dev.qweather.com/
2. 控制台 → 创建项目 → 创建凭证，获取 **API Key**
3. 免费版即可满足本 App 的调用需求

### 3. 配置 API Key

复制配置样例并填入你的 Key（**该文件被 .gitignore 忽略，不会提交**）：

```bash
cp lib/config/env.dart lib/config/env.dart
```

编辑 `lib/config/env.dart`：

```dart
class Env {
  static const String apiKey = '你的_和风天气_Key';
  ...
}
```

### 4. 初始化原生工程

首次运行前需生成 iOS / Android 原生目录：

```bash
flutter create .
```

### 5. 配置定位权限

- **iOS**：在 `ios/Runner/Info.plist` 添加：

  ```xml
  <key>NSLocationWhenInUseUsageDescription</key>
  <string>用于获取您当前城市的天气</string>
  ```

- **Android**：在 `android/app/src/main/AndroidManifest.xml` 的 `<manifest>` 下添加：

  ```xml
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
  ```

### 6. 运行

```bash
flutter pub get
flutter run
```

## 项目结构

```
lib/
├── config/env.dart            # API Key 配置（gitignore 忽略）
├── models/                    # City / Weather 数据模型
├── data/                      # 远程 API / 本地缓存 / 定位服务
├── repositories/              # WeatherRepository 编排层
├── providers/                 # Riverpod 状态管理
└── ui/                        # 主页与卡片组件
```

## 说明

- 网络优先、缓存兜底：每次刷新都会尝试联网，失败时使用本地缓存，保证离线可用。
- API Key 一律走 `Env.apiKey`，禁止硬编码到其它文件。
- 免费版有每日调用配额，缓存策略可显著降低请求量。
