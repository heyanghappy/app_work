import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/weather_provider.dart';

/// 当前城市自动刷新：回到前台或每 30 分钟静默刷新一次已展示的天气数据。
///
/// 通过 [WidgetsBindingObserver] 监听应用生命周期，用 [Timer] 做周期刷新。
/// 仅在已有可展示数据（now != null）且非加载中时刷新，避免打断首页初次加载。
class AutoRefresh extends ConsumerStatefulWidget {
  final Widget child;

  const AutoRefresh({super.key, required this.child});

  @override
  ConsumerState<AutoRefresh> createState() => _AutoRefreshState();
}

class _AutoRefreshState extends ConsumerState<AutoRefresh>
    with WidgetsBindingObserver {
  static const Duration _interval = Duration(minutes: 30);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(_interval, (_) => _refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final activeId = ref.read(activeCityIdProvider);
    if (activeId == null) return;
    final state = ref.read(weatherProvider(activeId));
    // 已有可展示数据且不在加载中才静默刷新；否则保持现状（含初次加载/错误占位）。
    if (state.city != null && state.now != null && !state.loading) {
      await ref.read(weatherProvider(activeId).notifier).load(state.city!);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}