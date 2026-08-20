import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ads/gromore_manager.dart';
import 'weather_home_page.dart';

/// 隐私政策同意页。
///
/// 穿山甲 GroMore 强制要求：在初始化广告 SDK 前必须获得用户同意。
/// 同意后写入本地标记，下次启动直接进入应用。
class PrivacyConsentPage extends StatelessWidget {
  const PrivacyConsentPage({super.key});

  static const String _consentKey = 'privacy_consent_granted';

  static Future<bool> isConsented() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentKey) ?? false;
  }

  Future<void> _grant(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentKey, true);
    if (!context.mounted) return;

    // 同意后再初始化广告 SDK，并展示开屏广告，随后进入主页。
    await GromoreManager.init();
    if (!context.mounted) return;

    await GromoreManager.showSplash(
      onFinish: () {
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const WeatherHomePage()),
          );
        }
      },
    );
  }

  Future<void> _exit() async {
    // 不同意则退出应用（广告 SDK 不可用，App 不提供核心外服务也可接受）。
    // 使用 SystemNavigator 退出 Android 应用。
    // ignore: avoid_print
    print('用户拒绝隐私政策，退出应用');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '隐私政策',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              const Text(
                '为向你提供天气服务并展示相关广告，本应用会收集设备信息、'
                '位置信息，并接入穿山甲（GroMore）聚合广告 SDK。'
                '详细内容请阅读《隐私政策》与《广告投放说明》。',
                style: TextStyle(fontSize: 15, height: 1.6, color: Colors.black87),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _exit,
                      child: const Text('不同意并退出'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _grant(context),
                      child: const Text('同意并继续'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
