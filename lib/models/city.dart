/// 城市模型。
class City {
  final String id; // 和风 LocationID，例如 101010100
  final String name; // 展示名称，例如 北京
  final String? adm1; // 一级行政区（省/直辖市）
  final String? adm2; // 二级行政区（市/区）
  final double? lat;
  final double? lon;
  final bool isLocated; // 是否为定位到的当前城市

  const City({
    required this.id,
    required this.name,
    this.adm1,
    this.adm2,
    this.lat,
    this.lon,
    this.isLocated = false,
  });

  /// 用于搜索结果去重 / 列表展示的完整名称。
  String get fullName =>
      [adm1, name].where((e) => e != null && e.isNotEmpty).join(' · ');

  factory City.fromGeoJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as String,
      name: json['name'] as String,
      adm1: json['adm1'] as String?,
      adm2: json['adm2'] as String?,
      lat: (json['lat'] as String?) == null ? null : double.tryParse(json['lat']),
      lon: (json['lon'] as String?) == null ? null : double.tryParse(json['lon']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'adm1': adm1,
        'adm2': adm2,
        'lat': lat,
        'lon': lon,
        'isLocated': isLocated,
      };

  factory City.fromJson(Map<String, dynamic> json) => City(
        id: json['id'] as String,
        name: json['name'] as String,
        adm1: json['adm1'] as String?,
        adm2: json['adm2'] as String?,
        lat: json['lat'] as double?,
        lon: json['lon'] as double?,
        isLocated: json['isLocated'] as bool? ?? false,
      );

  City copyWith({bool? isLocated}) =>
      City(id: id, name: name, adm1: adm1, adm2: adm2, lat: lat, lon: lon, isLocated: isLocated ?? this.isLocated);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is City && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
