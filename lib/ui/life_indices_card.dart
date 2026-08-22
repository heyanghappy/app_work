import 'package:flutter/material.dart';

import '../models/indices.dart';
import 'theme_colors.dart';

/// 生活指数卡片。
///
/// 生活指数用 2 列网格平铺（无需横向滑动），带 emoji 图标。
class LifeIndicesCard extends StatelessWidget {
  final List<IndicesItem> indices;

  const LifeIndicesCard({super.key, required this.indices});

  @override
  Widget build(BuildContext context) {
    if (indices.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('生活指数',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              // 每行 2 个，间距 12；内容高度自适应，避免 aspectRatio 溢出。
              final itemWidth = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: indices
                    .map((e) => SizedBox(
                          width: itemWidth,
                          child: _IndexItem(item: e),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _IndexItem extends StatelessWidget {
  final IndicesItem item;
  const _IndexItem({required this.item});

  String get _emoji {
    switch (item.type) {
      case '1':
        return '🏃'; // 运动
      case '2':
        return '🚗'; // 洗车
      case '3':
        return '👕'; // 穿衣
      case '5':
        return '🕶️'; // 紫外线
      case '9':
        return '🤧'; // 感冒
      case '6':
        return '🚲'; // 交通
      case '7':
        return '🎣'; // 钓鱼
      case '8':
        return '💄'; // 化妆
      case '10':
        return '🌬️'; // 空气污染扩散
      case '11':
        return '🏔️'; // 旅游
      case '12':
        return '🌌'; // 观星
      default:
        return '📊';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.subtleColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(_emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(item.category,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade400),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
