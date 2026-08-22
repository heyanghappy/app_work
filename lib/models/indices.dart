/// 生活指数单项（穿衣/洗车/运动/紫外线等）。
class IndicesItem {
  final String type; // 指数类型代码，如 1=运动,3=穿衣,9=感冒
  final String name; // 中文名，如「运动指数」
  final String category; // 等级，如「适宜」「较不宜」
  final String text; // 建议文字

  const IndicesItem({
    required this.type,
    required this.name,
    required this.category,
    required this.text,
  });

  factory IndicesItem.fromJson(Map<String, dynamic> json) {
    return IndicesItem(
      type: json['type'] as String,
      name: json['name'] as String? ?? _defaultName(json['type'] as String? ?? ''),
      category: json['category'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }

  /// 部分字段缺失时的兜底中文名。
  static String _defaultName(String type) {
    switch (type) {
      case '1':
        return '运动指数';
      case '2':
        return '洗车指数';
      case '3':
        return '穿衣指数';
      case '5':
        return '紫外线指数';
      case '9':
        return '感冒指数';
      default:
        return '生活指数';
    }
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'name': name,
        'category': category,
        'text': text,
      };
}
