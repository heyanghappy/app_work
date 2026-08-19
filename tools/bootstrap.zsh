#!/bin/zsh
# 一键初始化：解压 Flutter SDK + 生成原生工程 + 注入权限 + 拉取依赖。
# 前置：/tmp/flutter_macos.zip 已下载完成。
# 用法：zsh tools/bootstrap.zsh
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DL="/tmp/flutter_macos.zip"

if [ ! -f "$DL" ]; then
  echo "错误：未找到 $DL，请先下载 Flutter SDK。"
  exit 1
fi
if [ $(stat -f%z "$DL") -lt 2200000000 ]; then
  echo "错误：Flutter 压缩包似乎未下载完整（$(stat -f%z "$DL") 字节），请先完成下载。"
  exit 1
fi

echo "==> 解压 Flutter SDK 到 $ROOT/flutter"
rm -rf "$ROOT/flutter"
ditto -x -k "$DL" "$ROOT"   # macOS 原生解压，避免 unzip 长路径问题
# 压缩包顶层目录为 flutter/
if [ -d "$ROOT/flutter" ]; then
  echo "    已解压"
else
  echo "    解压后未找到 flutter 目录，请检查压缩包结构"
  exit 1
fi

export PATH="$ROOT/flutter/bin:$PATH"
echo "==> flutter version"
flutter --version

echo "==> flutter create . (生成 iOS/Android 原生工程)"
flutter create --org com.example . 

echo "==> 注入定位权限"
zsh "$ROOT/tools/setup_native_perms.zsh"

echo "==> flutter pub get"
flutter pub get

echo ""
echo "初始化完成！接下来："
echo "  1. 编辑 lib/config/env.dart 填入你的和风天气 API Key"
echo "  2. flutter run"
