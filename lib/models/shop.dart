class Shop {
  final String id;
  final String name;
  final String description;
  final int healthyCount;
  final int totalItems;
  final String campus;

  const Shop({
    required this.id,
    required this.name,
    required this.description,
    required this.healthyCount,
    required this.totalItems,
    required this.campus,
  });

  factory Shop.fromJson(Map<String, dynamic> json) => Shop(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        healthyCount: (json['healthyCount'] as num?)?.toInt() ?? 0,
        totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
        campus: json['campus'] as String? ?? '',
      );
}
