#!/bin/zsh
# 在 `flutter create .` 之后运行，自动注入定位权限配置。
# 用法：zsh tools/setup_native_perms.zsh
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> 配置 iOS 定位权限 (Info.plist)"
PLIST="ios/Runner/Info.plist"
if [ -f "$PLIST" ]; then
  if ! /usr/libexec/PlistBuddy -c "Print :NSLocationWhenInUseUsageDescription" "$PLIST" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c "Add :NSLocationWhenInUseUsageDescription string '用于获取您当前城市的天气'" "$PLIST"
    echo "    已添加 NSLocationWhenInUseUsageDescription"
  else
    echo "    已存在，跳过"
  fi
else
  echo "    未找到 $PLIST，请先运行 flutter create ."
fi

echo "==> 配置 Android 权限 (AndroidManifest.xml)"
MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST" ]; then
  # INTERNET：release 包不会自动合并，必须显式声明，否则真机无法访问天气 API
  if ! grep -q "android.permission.INTERNET" "$MANIFEST"; then
    perl -0pi -e 's{(<manifest[^>]*>)}{$1\n    <uses-permission android:name="android.permission.INTERNET" />}' "$MANIFEST"
    echo "    已添加 INTERNET 权限"
  else
    echo "    INTERNET 已存在，跳过"
  fi
  # 定位权限
  if ! grep -q "ACCESS_FINE_LOCATION" "$MANIFEST"; then
    perl -0pi -e 's{(<manifest[^>]*>)}{$1\n    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />\n    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />}' "$MANIFEST"
    echo "    已添加 ACCESS_FINE_LOCATION / ACCESS_COARSE_LOCATION"
  else
    echo "    定位权限已存在，跳过"
  fi
else
  echo "    未找到 $MANIFEST，请先运行 flutter create ."
fi

echo "完成。"
