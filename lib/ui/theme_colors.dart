import 'package:flutter/material.dart';

/// 跟随亮/暗主题的常用颜色。
///
/// 组件中避免硬编码 Colors.white 等，统一从这里取色，
/// 以便深色模式下卡片/文字自动适配。
extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// 卡片背景色（亮=白，暗=深灰）。
  Color get cardColor => isDark ? const Color(0xFF1E2228) : Colors.white;

  /// 次级卡片/浅灰背景（亮=灰50，暗=灰900）。
  Color get subtleColor =>
      isDark ? const Color(0xFF2A2F37) : const Color(0xFFF7F8FA);

  /// 次要文字色。
  Color get mutedColor => isDark ? Colors.white54 : Colors.grey;

  /// 分割线/描边色。
  Color get dividerColor => isDark ? Colors.white12 : Colors.grey.shade200;
}
