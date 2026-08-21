import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ads/gromore_manager.dart';
import 'providers/weather_provider.dart';
import 'ui/privacy_consent_page.dart';
import 'ui/weather_home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '极简天气',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // 不指定自定义 fontFamily，交由 web/index.html 的 CSS 字体回退渲染中文，
        // 避免 Flutter Web 找不到字体时的 Noto 警告与豆腐块。
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A90D9)),
      ),
      home: const AppEntry(),
    );
  }
}

/// 应用入口：先判断是否已同意隐私政策，再决定展示同意页或主流程。
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool? _consented;

  @override
  void initState() {
    super.initState();
    _checkConsent();
  }

  Future<void> _checkConsent() async {
    final granted = await PrivacyConsentPage.isConsented();
    if (mounted) setState(() => _consented = granted);
  }

  @override
  Widget build(BuildContext context) {
    if (_consented == null) {
      return const _SplashGate(); // 载入中
    }
    if (_consented == true) {
      return const _SplashGate(); // 已同意：初始化广告 + 开屏
    }
    return const PrivacyConsentPage(); // 未同意：先弹隐私页
  }
}

/// 已同意/待确认状态下：初始化 SDK、展示开屏广告，结束后进入主页。
class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await GromoreManager.init();
    if (!mounted) return;
    await GromoreManager.showSplash(
      onFinish: () {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pushReplacement(
            MaterialPageRoute(builder: (_) => const WeatherHomePage()),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 极简天气艺术背景图作为开屏界面，避免黑/白屏的空旷感。
    // 开屏广告容器由原生叠加在其上，广告关闭后进入主页，背景随之消失。
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'lib/assets/splash_bg.png',
            fit: BoxFit.cover,
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 320),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
